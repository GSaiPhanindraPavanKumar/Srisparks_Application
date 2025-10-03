import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/installation_project_model.dart';
import '../../services/installation_project_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InstallationProjectService _installationService =
      InstallationProjectService();
  InstallationProjectModel? _installationProject;
  bool _isLoadingInstallation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInstallationProject();
  }

  Future<void> _loadInstallationProject() async {
    setState(() => _isLoadingInstallation = true);
    try {
      final project = await _installationService.getProjectByCustomerId(
        widget.customer.id,
      );
      setState(() => _installationProject = project);
    } catch (e) {
      // Handle error silently - installation project might not exist yet
      setState(() => _installationProject = null);
    } finally {
      setState(() => _isLoadingInstallation = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Customer Details'),
            Tab(text: 'Site Survey'),
            Tab(text: 'Phase Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerDetailsTab(),
          _buildSiteSurveyTab(),
          _buildPhaseTimelineTab(),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPhaseChip(widget.customer.currentPhase),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    color: _getPhaseColor(widget.customer.currentPhase),
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Information
          _buildDetailSection('Contact Information', [
            _buildDetailRow('Name', widget.customer.name),
            _buildDetailRow('Email', widget.customer.email ?? 'N/A'),
            _buildDetailRow('Phone', widget.customer.phoneNumber ?? 'N/A'),
            _buildDetailRow('Address', widget.customer.address ?? 'N/A'),
            _buildDetailRow('City', widget.customer.city ?? 'N/A'),
          ]),

          // Project Details
          _buildDetailSection('Project Details', [
            _buildDetailRow('KW Capacity', '${widget.customer.kw ?? 'N/A'} KW'),
            _buildDetailRow(
              'Electric Meter',
              widget.customer.electricMeterServiceNumber ?? 'N/A',
            ),
            _buildDetailRow(
              'Estimated KW',
              '${widget.customer.estimatedKw ?? 'N/A'} KW',
            ),
            _buildDetailRow(
              'Estimated Cost',
              '₹${widget.customer.estimatedCost?.toStringAsFixed(0) ?? 'N/A'}',
            ),
            _buildDetailRow(
              'Created Date',
              DateFormat('dd/MM/yyyy HH:mm').format(widget.customer.createdAt),
            ),
          ]),

          // Application Status
          if (widget.customer.currentPhase == 'application' ||
              widget.customer.applicationStatus.isNotEmpty)
            _buildDetailSection('Application Status', [
              _buildDetailRow(
                'Status',
                widget.customer.applicationStatus.toUpperCase(),
              ),
              if (widget.customer.applicationApprovalDate != null)
                _buildDetailRow(
                  'Approved On',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(widget.customer.applicationApprovalDate!),
                ),
              if (widget.customer.managerRecommendation != null)
                _buildDetailRow(
                  'Manager Recommendation',
                  widget.customer.managerRecommendation!.toUpperCase(),
                ),
            ]),

          // Amount Details
          if (widget.customer.currentPhase == 'amount' ||
              (widget.customer.amountTotal != null &&
                  widget.customer.amountTotal! > 0))
            _buildDetailSection('Amount Information', [
              _buildDetailRow(
                'Total Amount',
                '₹${widget.customer.amountTotal?.toStringAsFixed(0) ?? 'N/A'}',
              ),
              _buildDetailRow(
                'Amount Paid',
                '₹${widget.customer.totalAmountPaid.toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Pending Amount',
                '₹${widget.customer.pendingAmount.toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Payment Status',
                widget.customer.calculatedPaymentStatus.toUpperCase(),
              ),
              _buildDetailRow(
                'Number of Payments',
                '${widget.customer.paymentHistory.length}',
              ),
              if (widget.customer.amountNotes?.isNotEmpty == true)
                _buildDetailRow('Notes', widget.customer.amountNotes!),
            ]),

          // Payment History Details
          if (widget.customer.paymentHistory.isNotEmpty)
            _buildDetailSection('Payment History', [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: Colors.teal.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Transactions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(
                                widget.customer.calculatedPaymentStatus,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.customer.calculatedPaymentStatus
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Payment Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPaymentSummaryItem(
                              'Total Amount',
                              '₹${widget.customer.amountTotal?.toStringAsFixed(0) ?? '0'}',
                              Colors.blue,
                              Icons.account_balance_wallet,
                            ),
                          ),
                          Expanded(
                            child: _buildPaymentSummaryItem(
                              'Amount Paid',
                              '₹${widget.customer.totalAmountPaid.toStringAsFixed(0)}',
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _buildPaymentSummaryItem(
                              'Pending',
                              '₹${widget.customer.pendingAmount.toStringAsFixed(0)}',
                              Colors.orange,
                              Icons.pending,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Payment List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.customer.paymentHistory.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final payment = widget.customer.paymentHistory[index];
                        final amount = payment['amount']?.toDouble() ?? 0.0;
                        final date =
                            DateTime.tryParse(payment['date'] ?? '') ??
                            DateTime.now();
                        final utr = payment['utr_number'] ?? '';
                        final notes = payment['notes'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.payment,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(date),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'UTR: $utr',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.note,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              notes,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('HH:mm').format(date),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSiteSurveyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Survey Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.customer.siteSurveyCompleted == true
                            ? Icons.check_circle
                            : Icons.pending,
                        color: widget.customer.siteSurveyCompleted == true
                            ? Colors.green
                            : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.siteSurveyCompleted == true
                                  ? 'Site Survey Completed'
                                  : 'Site Survey Pending',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.customer.siteSurveyDate != null)
                              Text(
                                'Completed on: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.customer.siteSurveyDate!)}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Action button for pending site survey
                  if (widget.customer.siteSurveyCompleted != true) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _conductSiteSurvey(),
                        icon: const Icon(Icons.location_searching),
                        label: const Text('Conduct Site Survey'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Survey Details
          _buildDetailSection('Survey Information', [
            _buildDetailRow(
              'Survey Status',
              widget.customer.siteSurveyCompleted == true
                  ? 'Completed'
                  : 'Pending',
            ),
            if (widget.customer.siteSurveyDate != null)
              _buildDetailRow(
                'Survey Date',
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(widget.customer.siteSurveyDate!),
              ),
            _buildDetailRow(
              'Feasibility Status',
              widget.customer.feasibilityStatus,
            ),
            if (widget.customer.managerRecommendation != null)
              _buildDetailRow(
                'Manager Recommendation',
                widget.customer.managerRecommendation!.toUpperCase(),
              ),
            if (widget.customer.managerRecommendationDate != null)
              _buildDetailRow(
                'Recommendation Date',
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(widget.customer.managerRecommendationDate!),
              ),
            if (widget.customer.managerRecommendationComment?.isNotEmpty ==
                true)
              _buildDetailRow(
                'Manager Comments',
                widget.customer.managerRecommendationComment!,
              ),
            if (widget.customer.applicationNotes?.isNotEmpty == true)
              _buildDetailRow(
                'Application Notes',
                widget.customer.applicationNotes!,
              ),
          ]),

          // Application Details from Site Survey
          if (widget.customer.applicationDetails != null)
            _buildDetailSection('Site Survey Application Details', [
              ...widget.customer.applicationDetails!.entries.map((entry) {
                String label = _formatFieldLabel(entry.key);
                String value = entry.value?.toString() ?? 'N/A';
                return _buildDetailRow(label, value);
              }).toList(),
            ])
          else
            _buildDetailSection('Site Survey Application Details', [
              _buildDetailRow('Customer Name', widget.customer.name),
              _buildDetailRow('Email', widget.customer.email ?? 'N/A'),
              _buildDetailRow(
                'Phone Number',
                widget.customer.phoneNumber ?? 'N/A',
              ),
              _buildDetailRow('Address', widget.customer.address ?? 'N/A'),
              _buildDetailRow('City', widget.customer.city ?? 'N/A'),
              _buildDetailRow(
                'Electric Meter Service Number',
                widget.customer.electricMeterServiceNumber ?? 'N/A',
              ),
              _buildDetailRow(
                'Requested KW Capacity',
                '${widget.customer.kw ?? widget.customer.estimatedKw ?? 'N/A'} KW',
              ),
              _buildDetailRow(
                'Application Date',
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(widget.customer.createdAt),
              ),
              if (widget.customer.applicationNotes?.isNotEmpty == true)
                _buildDetailRow(
                  'Customer Notes',
                  widget.customer.applicationNotes!,
                ),
            ]),

          // Technical Details
          if (widget.customer.siteSurveyCompleted == true)
            _buildDetailSection('Technical Assessment', [
              _buildDetailRow(
                'System Feasibility',
                widget.customer.feasibilityStatus,
              ),
              _buildDetailRow(
                'Recommended KW',
                '${widget.customer.estimatedKw ?? widget.customer.kw ?? 'N/A'} KW',
              ),
              if (widget.customer.estimatedCost != null)
                _buildDetailRow(
                  'Estimated Cost',
                  '₹${widget.customer.estimatedCost!.toStringAsFixed(0)}',
                ),
            ]),
        ],
      ),
    );
  }

  Widget _buildPhaseTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Journey Timeline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Timeline
          _buildTimelineItem(
            'Application Created',
            DateFormat('dd/MM/yyyy HH:mm').format(widget.customer.createdAt),
            true,
            Colors.blue,
            'Customer application submitted and received',
            Icons.assignment,
          ),

          if (widget.customer.siteSurveyDate != null)
            _buildTimelineItem(
              'Site Survey Completed',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.siteSurveyDate!),
              true,
              Colors.orange,
              'Technical assessment and feasibility check completed',
              Icons.location_searching,
            ),

          if (widget.customer.managerRecommendation != null)
            _buildTimelineItem(
              'Manager Recommendation - ${widget.customer.managerRecommendation?.toUpperCase()}',
              widget.customer.managerRecommendationDate != null
                  ? DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(widget.customer.managerRecommendationDate!)
                  : (widget.customer.siteSurveyDate != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(widget.customer.siteSurveyDate!)
                        : 'Date not available'),
              true,
              widget.customer.managerRecommendation == 'approval'
                  ? Colors.green
                  : Colors.red,
              'Manager has provided recommendation based on survey',
              widget.customer.managerRecommendation == 'approval'
                  ? Icons.thumb_up
                  : Icons.thumb_down,
            ),

          if (widget.customer.applicationApprovalDate != null)
            _buildTimelineItem(
              'Director Approval',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.applicationApprovalDate!),
              true,
              Colors.green,
              'Application has been approved by director',
              Icons.verified_user,
            ),

          if (widget.customer.paymentHistory.isNotEmpty)
            _buildTimelineItem(
              widget.customer.calculatedPaymentStatus == 'completed'
                  ? 'Payment Processed'
                  : 'Payment Processing',
              '${widget.customer.paymentHistory.length} payment(s) received',
              widget.customer.calculatedPaymentStatus == 'completed',
              widget.customer.calculatedPaymentStatus == 'completed'
                  ? Colors.green
                  : Colors.teal,
              widget.customer.calculatedPaymentStatus == 'completed'
                  ? 'All payments completed successfully'
                  : 'Payment in progress - ₹${widget.customer.totalAmountPaid.toStringAsFixed(0)} of ₹${widget.customer.amountTotal?.toStringAsFixed(0) ?? '0'} paid',
              Icons.payment,
            ),

          // Material Allocation Phases
          if (widget.customer.materialPlannedDate != null)
            _buildTimelineItem(
              'Material Planned',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.materialPlannedDate!),
              true,
              Colors.blue,
              'Material requirements planned and drafted',
              Icons.inventory_2,
            ),

          if (widget.customer.materialAllocationDate != null)
            _buildTimelineItem(
              'Material Allocated',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.materialAllocationDate!),
              true,
              Colors.orange,
              'Materials allocated and ready for delivery',
              Icons.local_shipping,
            ),

          if (widget.customer.materialConfirmedDate != null)
            _buildTimelineItem(
              'Material Confirmed',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.materialConfirmedDate!),
              true,
              Colors.green,
              'Material allocation confirmed and finalized',
              Icons.check_circle,
            ),

          // Material Delivery (based on status)
          if (widget.customer.materialDeliveredDate != null)
            _buildTimelineItem(
              'Material Delivered',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.materialDeliveredDate!),
              true,
              Colors.teal,
              'Materials delivered to site and ready for installation',
              Icons.local_shipping,
            ),

          // Installation Phase - This will be managed by installation_projects table
          _buildInstallationPhaseTimeline(),

          // Documentation Phase
          if (widget.customer.documentationSubmissionDate != null)
            _buildTimelineItem(
              'Documentation Submitted',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.documentationSubmissionDate!),
              true,
              Colors.blue,
              'Documentation submitted for government approvals',
              Icons.description,
            ),

          if (widget.customer.currentPhase == 'documentation' &&
              widget.customer.documentationSubmissionDate == null)
            _buildTimelineItem(
              'Documentation Phase',
              'In Progress',
              false,
              Colors.blue,
              'Preparing documentation for government approvals',
              Icons.description,
            ),

          // Meter Connection Phase
          if (widget.customer.dateOfMeter != null)
            _buildTimelineItem(
              'Meter Connected',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.dateOfMeter!),
              true,
              Colors.purple,
              'Grid connection and meter installation completed',
              Icons.electrical_services,
            ),

          if (widget.customer.currentPhase == 'meter_connection' &&
              widget.customer.dateOfMeter == null)
            _buildTimelineItem(
              'Meter Connection Phase',
              'In Progress',
              false,
              Colors.purple,
              'Grid connection and meter installation in progress',
              Icons.electrical_services,
            ),

          if (_hasPhaseCompleted('meter_connection') &&
              widget.customer.dateOfMeter == null)
            _buildTimelineItem(
              'Meter Connected',
              'Phase Completed',
              true,
              Colors.purple,
              'Grid connection established and meter installed',
              Icons.power,
            ),

          // Inverter Turn-on Phase
          if (widget.customer.dateOfInverter != null)
            _buildTimelineItem(
              'Inverter Turn-on',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.dateOfInverter!),
              true,
              Colors.amber,
              'Inverter turned on and system activated successfully',
              Icons.power_settings_new,
            ),

          if (widget.customer.currentPhase == 'inverter_turnon' &&
              widget.customer.dateOfInverter == null)
            _buildTimelineItem(
              'Inverter Turn-on Phase',
              'In Progress',
              false,
              Colors.amber,
              'System commissioning and inverter activation',
              Icons.power_settings_new,
            ),

          if (_hasPhaseCompleted('inverter_turnon') &&
              widget.customer.dateOfInverter == null)
            _buildTimelineItem(
              'Inverter Turn-on',
              'Phase Completed',
              true,
              Colors.amber,
              'Inverter turned on and system operational',
              Icons.flash_on,
            ),

          // Project Completion
          if (widget.customer.projectCompletedDate != null)
            _buildTimelineItem(
              'Project Completed',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(widget.customer.projectCompletedDate!),
              true,
              Colors.green,
              'Solar project successfully completed and handed over',
              Icons.check_circle_outline,
            ),

          if (widget.customer.currentPhase == 'completed' &&
              widget.customer.projectCompletedDate == null)
            _buildTimelineItem(
              'Project Completed',
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              true,
              Colors.green,
              'Solar project successfully completed and handed over',
              Icons.check_circle_outline,
            ),

          // Service Phase
          if (widget.customer.currentPhase == 'service_phase')
            _buildTimelineItem(
              'Service Phase',
              'Ongoing',
              true,
              Colors.lightGreen,
              'Project in service and maintenance phase',
              Icons.build,
            ),

          // Current phase indicator
          _buildTimelineItem(
            'Current Phase: ${_getPhaseDisplayName(widget.customer.currentPhase)}',
            'In Progress',
            false,
            _getPhaseColor(widget.customer.currentPhase),
            'Customer is currently in this phase',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationPhaseTimeline() {
    if (_isLoadingInstallation) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_installationProject == null) {
      // No installation project exists yet
      if (widget.customer.currentPhase == 'installation') {
        return _buildTimelineItem(
          'Installation Phase',
          'Pending Assignment',
          false,
          Colors.orange,
          'Installation project not yet created',
          Icons.construction,
        );
      }
      return const SizedBox.shrink();
    }

    final project = _installationProject!;
    return Column(
      children: [
        // Installation Project Created
        _buildTimelineItem(
          'Installation Assigned',
          project.assignedDate != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(project.assignedDate!)
              : DateFormat('dd/MM/yyyy HH:mm').format(project.createdAt),
          true,
          Colors.orange,
          'Installation project created and assigned',
          Icons.assignment,
        ),

        // Installation Started
        if (project.startedDate != null)
          _buildTimelineItem(
            'Installation Started',
            DateFormat('dd/MM/yyyy HH:mm').format(project.startedDate!),
            true,
            Colors.orange,
            'Solar panel installation work has begun',
            Icons.construction,
          ),

        // Installation in Progress
        if (project.isInProgress && project.startedDate != null)
          _buildTimelineItem(
            'Installation In Progress',
            'Ongoing',
            false,
            Colors.orange,
            'Solar panel installation work in progress',
            Icons.build,
          ),

        // Installation Completed
        if (project.completedDate != null)
          _buildTimelineItem(
            'Installation Completed',
            DateFormat('dd/MM/yyyy HH:mm').format(project.completedDate!),
            true,
            Colors.orange,
            'Solar panel installation work completed',
            Icons.solar_power,
          ),

        // Installation Verified
        if (project.isVerified)
          _buildTimelineItem(
            'Installation Verified',
            'Verified',
            true,
            Colors.green,
            'Installation quality verified and approved',
            Icons.verified,
          ),

        // Installation Approved
        if (project.isApproved)
          _buildTimelineItem(
            'Installation Approved',
            'Approved',
            true,
            Colors.green,
            'Installation officially approved and signed off',
            Icons.check_circle,
          ),

        // Show current status if not completed
        if (!project.isCompleted && !project.isVerified && !project.isApproved)
          _buildTimelineItem(
            'Installation Status',
            project.statusDisplayName,
            project.isInProgress,
            _getInstallationStatusColor(project.status),
            _getInstallationStatusDescription(project.status),
            _getInstallationStatusIcon(project.status),
          ),
      ],
    );
  }

  Color _getInstallationStatusColor(String status) {
    switch (status) {
      case 'created':
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'verified':
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getInstallationStatusDescription(String status) {
    switch (status) {
      case 'created':
        return 'Installation project created, awaiting assignment';
      case 'assigned':
        return 'Installation team assigned, work pending';
      case 'in_progress':
        return 'Installation work currently in progress';
      case 'completed':
        return 'Installation work completed, awaiting verification';
      case 'verified':
        return 'Installation verified and quality checked';
      case 'approved':
        return 'Installation approved and project complete';
      default:
        return 'Installation status unknown';
    }
  }

  IconData _getInstallationStatusIcon(String status) {
    switch (status) {
      case 'created':
        return Icons.create;
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.done;
      case 'verified':
        return Icons.verified;
      case 'approved':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    bool completed,
    Color color,
    String description,
    IconData? icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: completed ? color : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.circle,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (completed)
                Container(
                  width: 2,
                  height: 60,
                  color: color.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: completed ? color : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatFieldLabel(String key) {
    // Convert camelCase and snake_case to proper labels
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPhaseChip(String phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPhaseColor(phase).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getPhaseColor(phase)),
      ),
      child: Text(
        _getPhaseDisplayName(phase),
        style: TextStyle(
          color: _getPhaseColor(phase),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'application':
        return Colors.blue;
      case 'survey':
        return Colors.orange;
      case 'manager_review':
        return Colors.purple;
      case 'director_approval':
        return Colors.indigo;
      case 'approved':
        return Colors.green;
      case 'amount':
        return Colors.teal;
      case 'material':
      case 'material_allocation':
      case 'material_delivery':
        return Colors.brown;
      case 'installation':
      case 'documentation':
      case 'meter_connection':
      case 'inverter_turnon':
        return Colors.deepOrange;
      case 'completed':
      case 'service_phase':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPhaseDisplayName(String phase) {
    switch (phase.toLowerCase()) {
      case 'application':
        return 'Application';
      case 'survey':
        return 'Site Survey';
      case 'manager_review':
        return 'Manager Review';
      case 'director_approval':
        return 'Director Approval';
      case 'approved':
        return 'Approved';
      case 'amount':
        return 'Amount Phase';
      case 'material':
      case 'material_allocation':
        return 'Material Allocation';
      case 'material_delivery':
        return 'Material Delivery';
      case 'installation':
        return 'Installation';
      case 'documentation':
        return 'Documentation';
      case 'meter_connection':
        return 'Meter Connection';
      case 'inverter_turnon':
        return 'Inverter Turn On';
      case 'completed':
        return 'Completed';
      case 'service_phase':
        return 'Service Phase';
      default:
        return phase.toUpperCase();
    }
  }

  void _conductSiteSurvey() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conduct Site Survey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to conduct site survey for ${widget.customer.name}?'),
            const SizedBox(height: 16),
            const Text(
              'This will open the site survey form where you can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Record site measurements'),
            const Text('• Assess feasibility'),
            const Text('• Upload photos'),
            const Text('• Calculate estimated KW'),
            const Text('• Provide recommendations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSiteSurveyForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Survey'),
          ),
        ],
      ),
    );
  }

  void _openSiteSurveyForm() {
    // TODO: Navigate to site survey form
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Site survey form for ${widget.customer.name} - To be implemented',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Helper method to check if a phase has been completed based on current phase
  bool _hasPhaseCompleted(String phase) {
    // Define the phase order
    const phaseOrder = [
      'application',
      'amount',
      'material',
      'material_allocation',
      'material_delivery',
      'installation',
      'documentation',
      'meter_connection',
      'inverter_turnon',
      'completed',
      'service_phase',
    ];

    final currentPhaseIndex = phaseOrder.indexOf(widget.customer.currentPhase);
    final targetPhaseIndex = phaseOrder.indexOf(phase);

    // If current phase is later in the order, then the target phase is completed
    return currentPhaseIndex > targetPhaseIndex;
  }
}
