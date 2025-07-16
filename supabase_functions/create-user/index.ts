import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { email, password, full_name, role, phone_number, office_id, reporting_to_id, is_lead } = await req.json()

    // Get current user to check permissions
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabaseClient.auth.getUser(token)

    if (!user) {
      return new Response('Unauthorized', { status: 401, headers: corsHeaders })
    }

    // Check if user has permission to create users
    const { data: currentUser } = await supabaseClient
      .from('users')
      .select('role, is_lead, office_id')
      .eq('id', user.id)
      .single()

    if (!currentUser) {
      return new Response('User not found', { status: 404, headers: corsHeaders })
    }

    // Permission checks
    let canCreateUser = false
    let needsApproval = false

    if (currentUser.role === 'director') {
      canCreateUser = true
      needsApproval = false
    } else if (currentUser.role === 'manager') {
      // Managers can create employees in their office
      if (role === 'employee' && office_id === currentUser.office_id) {
        canCreateUser = true
        needsApproval = is_lead // Leads created by managers need approval
      }
    } else if (currentUser.is_lead) {
      // Leads can create employees who report to them
      if (role === 'employee' && reporting_to_id === currentUser.id) {
        canCreateUser = true
        needsApproval = true // All users created by leads need approval
      }
    }

    if (!canCreateUser) {
      return new Response('Forbidden - Insufficient permissions', { status: 403, headers: corsHeaders })
    }

    // Validate role
    if (!['director', 'manager', 'employee'].includes(role)) {
      return new Response('Invalid role', { status: 400, headers: corsHeaders })
    }

    // Only employees can be leads
    if (is_lead && role !== 'employee') {
      return new Response('Only employees can be leads', { status: 400, headers: corsHeaders })
    }

    // Create auth user
    const { data: authUser, error: authError } = await supabaseClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    })

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Create user profile
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('users')
      .insert({
        id: authUser.user.id,
        email,
        full_name,
        role,
        phone_number,
        office_id,
        reporting_to_id,
        is_lead: is_lead || false,
        status: needsApproval ? 'pending_approval' : 'active'
      })
      .select()
      .single()

    if (profileError) {
      // If profile creation fails, cleanup the auth user
      await supabaseClient.auth.admin.deleteUser(authUser.user.id)
      return new Response(JSON.stringify({ error: profileError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Log the activity
    await supabaseClient
      .from('activity_logs')
      .insert({
        user_id: user.id,
        activity_type: 'user_created',
        description: `Created user: ${full_name} (${email}) with role: ${role}${is_lead ? ' (Lead)' : ''}`,
        entity_id: userProfile.id,
        entity_type: 'user',
        new_data: userProfile
      })

    return new Response(JSON.stringify({
      ...userProfile,
      needsApproval,
      message: needsApproval ? 'User created successfully. Approval required.' : 'User created successfully.'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
