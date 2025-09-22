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

    const { email, password, full_name, role, phone_number, office_id, is_lead } = await req.json()

    console.log('Create user request:', { 
      email, 
      role, 
      office_id, 
      is_lead, 
      full_name,
      phone_number: phone_number ? '[PRESENT]' : null
    })

    // Get current user to check permissions
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabaseClient.auth.getUser(token)

    if (!user) {
      return new Response('Unauthorized', { status: 401, headers: corsHeaders })
    }

    // Get current user profile to check permissions
    const { data: currentUser } = await supabaseClient
      .from('users')
      .select('role, is_lead, office_id, approval_status, status')
      .eq('id', user.id)
      .single()

    if (!currentUser) {
      return new Response('User not found', { status: 404, headers: corsHeaders })
    }

    // Only active, approved users can create users
    if (currentUser.status !== 'active' || currentUser.approval_status !== 'approved') {
      return new Response('Forbidden - User not active or approved', { status: 403, headers: corsHeaders })
    }

    // Permission checks and approval logic
    let canCreateUser = false
    let autoApprove = false

    if (currentUser.role === 'director') {
      // Directors can create any user and auto-approve them
      canCreateUser = true
      autoApprove = true
    } else if (currentUser.role === 'manager') {
      // Managers can create employees in their office (requires director approval)
      if (role === 'employee' && office_id === currentUser.office_id) {
        canCreateUser = true
        autoApprove = false
      }
    } else if (currentUser.role === 'employee' && currentUser.is_lead) {
      // Employee-leads can create employees in their office (requires director approval)
      if (role === 'employee' && office_id === currentUser.office_id) {
        canCreateUser = true
        autoApprove = false
      }
    }

    if (!canCreateUser) {
      return new Response('Forbidden - Insufficient permissions', { status: 403, headers: corsHeaders })
    }

    // Validate required fields
    if (!email || !password || !full_name || !role) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Validate office_id requirements
    if (role !== 'director' && !office_id) {
      return new Response(JSON.stringify({ error: 'office_id is required for non-director roles' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Validate role
    if (!['director', 'manager', 'employee'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Invalid role' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Only employees can be leads
    if (is_lead && role !== 'employee') {
      return new Response(JSON.stringify({ error: 'Only employees can be leads' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
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

    // Determine user status and approval based on creator
    const userStatus = autoApprove ? 'active' : 'inactive'
    const approvalStatus = autoApprove ? 'approved' : 'pending'
    const approvedBy = autoApprove ? user.id : null
    const approvedTime = autoApprove ? new Date().toISOString() : null

    // Create user profile with approval workflow data
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('users')
      .insert({
        id: authUser.user.id,
        email,
        full_name,
        role: role,
        phone_number,
        office_id,
        is_lead: is_lead || false,
        status: userStatus,
        added_by: user.id,
        added_time: new Date().toISOString(),
        approved_by: approvedBy,
        approved_time: approvedTime,
        approval_status: approvalStatus
      })
      .select()
      .single()

    if (profileError) {
      // If profile creation fails, cleanup the auth user
      console.error('Profile creation error:', profileError)
      await supabaseClient.auth.admin.deleteUser(authUser.user.id)
      return new Response(JSON.stringify({ error: profileError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log('User created successfully:', userProfile)

    // Log the activity
    await supabaseClient
      .from('activity_logs')
      .insert({
        user_id: user.id,
        activity_type: autoApprove ? 'user_created_and_approved' : 'user_created_pending',
        description: `Created user: ${full_name} (${email}) with role: ${role}${is_lead ? ' (Lead)' : ''}${autoApprove ? ' - Auto approved' : ' - Pending approval'}`,
        entity_id: userProfile.id,
        entity_type: 'user',
        new_data: userProfile
      })

    const responseMessage = autoApprove 
      ? 'User created and approved successfully.'
      : 'User created successfully. Director approval required before activation.'

    return new Response(JSON.stringify({
      ...userProfile,
      needsApproval: !autoApprove,
      message: responseMessage
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (error) {
    console.error('Create user error:', error)
    return new Response(JSON.stringify({ 
      error: error instanceof Error ? error.message : 'Unknown error occurred' 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
