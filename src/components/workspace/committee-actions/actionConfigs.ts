import { ActionDialogConfig } from './CommitteeActionDialog';

// Committee action configurations organized by committee type and action id
export const actionConfigs: Record<string, Record<string, ActionDialogConfig>> = {
  // ============ VOLUNTEERS COMMITTEE ============
  volunteers: {
    'assign-shifts': {
      title: 'Assign Volunteer Shifts',
      description: 'Assign volunteers to available shifts for the event.',
      fields: [
        { name: 'volunteer', label: 'Volunteer Name', type: 'text', placeholder: 'Search volunteer...', required: true },
        { name: 'shift', label: 'Shift', type: 'select', options: [
          { value: 'morning', label: 'Morning (8AM - 12PM)' },
          { value: 'afternoon', label: 'Afternoon (12PM - 5PM)' },
          { value: 'evening', label: 'Evening (5PM - 10PM)' },
        ], required: true },
        { name: 'date', label: 'Date', type: 'date', required: true },
        { name: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Any special instructions...' },
      ],
      submitLabel: 'Assign Shift',
      successMessage: 'Volunteer shift assigned successfully!',
    },
    'send-brief': {
      title: 'Send Volunteer Brief',
      description: 'Send briefing information to volunteers.',
      fields: [
        { name: 'recipients', label: 'Recipients', type: 'select', options: [
          { value: 'all', label: 'All Volunteers' },
          { value: 'morning', label: 'Morning Shift' },
          { value: 'afternoon', label: 'Afternoon Shift' },
          { value: 'evening', label: 'Evening Shift' },
        ], required: true },
        { name: 'subject', label: 'Subject', type: 'text', placeholder: 'Brief subject...', required: true },
        { name: 'message', label: 'Message', type: 'textarea', placeholder: 'Write your brief...', required: true },
      ],
      submitLabel: 'Send Brief',
      successMessage: 'Brief sent to volunteers!',
    },
    'check-in': {
      title: 'Check-in Volunteer',
      description: 'Record volunteer check-in for their shift.',
      fields: [
        { name: 'volunteerId', label: 'Volunteer ID or Name', type: 'text', placeholder: 'Enter ID or search name...', required: true },
        { name: 'shift', label: 'Shift', type: 'select', options: [
          { value: 'morning', label: 'Morning Shift' },
          { value: 'afternoon', label: 'Afternoon Shift' },
          { value: 'evening', label: 'Evening Shift' },
        ], required: true },
      ],
      submitLabel: 'Check In',
      successMessage: 'Volunteer checked in successfully!',
    },
    'create-team': {
      title: 'Create Volunteer Team',
      description: 'Create a new team for volunteer coordination.',
      fields: [
        { name: 'teamName', label: 'Team Name', type: 'text', placeholder: 'e.g., Registration Desk Team', required: true },
        { name: 'lead', label: 'Team Lead', type: 'text', placeholder: 'Assign team lead...', required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Team responsibilities...' },
      ],
      submitLabel: 'Create Team',
      successMessage: 'Volunteer team created!',
    },
    'training-status': {
      title: 'Update Training Status',
      description: 'Update volunteer training completion status.',
      fields: [
        { name: 'volunteer', label: 'Volunteer', type: 'text', placeholder: 'Search volunteer...', required: true },
        { name: 'training', label: 'Training Module', type: 'select', options: [
          { value: 'orientation', label: 'Event Orientation' },
          { value: 'safety', label: 'Safety Training' },
          { value: 'customer-service', label: 'Customer Service' },
          { value: 'technical', label: 'Technical Training' },
        ], required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'completed', label: 'Completed' },
          { value: 'in-progress', label: 'In Progress' },
          { value: 'not-started', label: 'Not Started' },
        ], required: true },
      ],
      submitLabel: 'Update Status',
      successMessage: 'Training status updated!',
    },
    'performance-review': {
      title: 'Submit Performance Review',
      description: 'Submit a performance review for a volunteer.',
      fields: [
        { name: 'volunteer', label: 'Volunteer', type: 'text', placeholder: 'Search volunteer...', required: true },
        { name: 'rating', label: 'Overall Rating', type: 'select', options: [
          { value: '5', label: '⭐⭐⭐⭐⭐ Excellent' },
          { value: '4', label: '⭐⭐⭐⭐ Good' },
          { value: '3', label: '⭐⭐⭐ Average' },
          { value: '2', label: '⭐⭐ Below Average' },
          { value: '1', label: '⭐ Needs Improvement' },
        ], required: true },
        { name: 'feedback', label: 'Feedback', type: 'textarea', placeholder: 'Provide constructive feedback...', required: true },
      ],
      submitLabel: 'Submit Review',
      successMessage: 'Performance review submitted!',
    },
  },

  // ============ FINANCE COMMITTEE ============
  finance: {
    'record-expense': {
      title: 'Record Expense',
      description: 'Record a new expense transaction.',
      fields: [
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'venue', label: 'Venue' },
          { value: 'catering', label: 'Catering' },
          { value: 'equipment', label: 'Equipment' },
          { value: 'marketing', label: 'Marketing' },
          { value: 'travel', label: 'Travel' },
          { value: 'other', label: 'Other' },
        ], required: true },
        { name: 'amount', label: 'Amount', type: 'number', placeholder: '0.00', required: true },
        { name: 'vendor', label: 'Vendor/Payee', type: 'text', placeholder: 'Vendor name...', required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Expense details...' },
        { name: 'date', label: 'Date', type: 'date', required: true },
      ],
      submitLabel: 'Record Expense',
      successMessage: 'Expense recorded successfully!',
    },
    'generate-report': {
      title: 'Generate Financial Report',
      description: 'Generate a financial report for the selected period.',
      fields: [
        { name: 'reportType', label: 'Report Type', type: 'select', options: [
          { value: 'summary', label: 'Budget Summary' },
          { value: 'expenses', label: 'Expense Report' },
          { value: 'income', label: 'Income Report' },
          { value: 'comparison', label: 'Budget vs Actual' },
        ], required: true },
        { name: 'startDate', label: 'Start Date', type: 'date', required: true },
        { name: 'endDate', label: 'End Date', type: 'date', required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'pdf', label: 'PDF' },
          { value: 'excel', label: 'Excel' },
          { value: 'csv', label: 'CSV' },
        ], required: true },
      ],
      submitLabel: 'Generate Report',
      successMessage: 'Report generated and ready for download!',
    },
    'approve-request': {
      title: 'Approve Budget Request',
      description: 'Review and approve a pending budget request.',
      fields: [
        { name: 'requestId', label: 'Request ID', type: 'text', placeholder: 'Enter request ID...', required: true },
        { name: 'decision', label: 'Decision', type: 'select', options: [
          { value: 'approve', label: 'Approve' },
          { value: 'approve-partial', label: 'Approve Partially' },
          { value: 'reject', label: 'Reject' },
        ], required: true },
        { name: 'approvedAmount', label: 'Approved Amount', type: 'number', placeholder: '0.00' },
        { name: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Decision notes...' },
      ],
      submitLabel: 'Submit Decision',
      successMessage: 'Budget request decision recorded!',
    },
    'view-budget': {
      title: 'View Budget Allocation',
      description: 'View current budget allocation and spending.',
      fields: [
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'all', label: 'All Categories' },
          { value: 'venue', label: 'Venue' },
          { value: 'catering', label: 'Catering' },
          { value: 'marketing', label: 'Marketing' },
          { value: 'logistics', label: 'Logistics' },
        ], required: true },
      ],
      submitLabel: 'View Budget',
      successMessage: 'Budget data loaded!',
    },
    'export-data': {
      title: 'Export Financial Data',
      description: 'Export financial data for external use.',
      fields: [
        { name: 'dataType', label: 'Data Type', type: 'select', options: [
          { value: 'transactions', label: 'All Transactions' },
          { value: 'expenses', label: 'Expenses Only' },
          { value: 'income', label: 'Income Only' },
          { value: 'budget', label: 'Budget Allocation' },
        ], required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'csv', label: 'CSV' },
          { value: 'excel', label: 'Excel' },
          { value: 'json', label: 'JSON' },
        ], required: true },
      ],
      submitLabel: 'Export Data',
      successMessage: 'Data exported successfully!',
    },
  },

  // ============ REGISTRATION COMMITTEE ============
  registration: {
    'scan-checkin': {
      title: 'Scan Check-in',
      description: 'Scan attendee QR code or enter ID for check-in.',
      fields: [
        { name: 'attendeeId', label: 'Attendee ID or Ticket #', type: 'text', placeholder: 'Scan or enter ID...', required: true },
        { name: 'method', label: 'Check-in Method', type: 'select', options: [
          { value: 'qr', label: 'QR Code' },
          { value: 'manual', label: 'Manual Entry' },
          { value: 'id', label: 'ID Lookup' },
        ], required: true },
      ],
      submitLabel: 'Check In',
      successMessage: 'Attendee checked in successfully!',
    },
    'add-attendee': {
      title: 'Add Attendee',
      description: 'Register a new attendee on-site.',
      fields: [
        { name: 'fullName', label: 'Full Name', type: 'text', placeholder: 'Attendee name...', required: true },
        { name: 'email', label: 'Email', type: 'email', placeholder: 'email@example.com', required: true },
        { name: 'phone', label: 'Phone', type: 'text', placeholder: '+1 (555) 000-0000' },
        { name: 'ticketType', label: 'Ticket Type', type: 'select', options: [
          { value: 'general', label: 'General Admission' },
          { value: 'vip', label: 'VIP' },
          { value: 'speaker', label: 'Speaker' },
          { value: 'sponsor', label: 'Sponsor' },
        ], required: true },
      ],
      submitLabel: 'Add Attendee',
      successMessage: 'Attendee registered successfully!',
    },
    'export-list': {
      title: 'Export Attendee List',
      description: 'Export the attendee list in your preferred format.',
      fields: [
        { name: 'listType', label: 'List Type', type: 'select', options: [
          { value: 'all', label: 'All Registrations' },
          { value: 'checked-in', label: 'Checked In Only' },
          { value: 'not-checked-in', label: 'Not Checked In' },
        ], required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'csv', label: 'CSV' },
          { value: 'excel', label: 'Excel' },
          { value: 'pdf', label: 'PDF' },
        ], required: true },
      ],
      submitLabel: 'Export List',
      successMessage: 'Attendee list exported!',
    },
    'send-reminders': {
      title: 'Send Reminders',
      description: 'Send reminder emails to attendees.',
      fields: [
        { name: 'recipients', label: 'Recipients', type: 'select', options: [
          { value: 'all', label: 'All Registered' },
          { value: 'not-checked-in', label: 'Not Checked In' },
          { value: 'vip', label: 'VIP Only' },
        ], required: true },
        { name: 'subject', label: 'Subject', type: 'text', placeholder: 'Reminder subject...', required: true },
        { name: 'message', label: 'Message', type: 'textarea', placeholder: 'Reminder message...', required: true },
      ],
      submitLabel: 'Send Reminders',
      successMessage: 'Reminders sent successfully!',
    },
    'view-waitlist': {
      title: 'Manage Waitlist',
      description: 'View and manage the event waitlist.',
      fields: [
        { name: 'action', label: 'Action', type: 'select', options: [
          { value: 'view', label: 'View Waitlist' },
          { value: 'admit-next', label: 'Admit Next Person' },
          { value: 'notify-all', label: 'Notify All' },
        ], required: true },
      ],
      submitLabel: 'Execute',
      successMessage: 'Waitlist action completed!',
    },
  },

  // ============ CATERING COMMITTEE ============
  catering: {
    'update-menu': {
      title: 'Update Menu',
      description: 'Update the catering menu for the event.',
      fields: [
        { name: 'mealType', label: 'Meal Type', type: 'select', options: [
          { value: 'breakfast', label: 'Breakfast' },
          { value: 'lunch', label: 'Lunch' },
          { value: 'dinner', label: 'Dinner' },
          { value: 'snacks', label: 'Snacks & Beverages' },
        ], required: true },
        { name: 'itemName', label: 'Item Name', type: 'text', placeholder: 'Menu item...', required: true },
        { name: 'dietary', label: 'Dietary Options', type: 'select', options: [
          { value: 'regular', label: 'Regular' },
          { value: 'vegetarian', label: 'Vegetarian' },
          { value: 'vegan', label: 'Vegan' },
          { value: 'gluten-free', label: 'Gluten-Free' },
          { value: 'halal', label: 'Halal' },
        ], required: true },
        { name: 'servings', label: 'Number of Servings', type: 'number', placeholder: '100', required: true },
      ],
      submitLabel: 'Update Menu',
      successMessage: 'Menu updated successfully!',
    },
    'check-inventory': {
      title: 'Check Inventory',
      description: 'Check current inventory levels.',
      fields: [
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'food', label: 'Food Items' },
          { value: 'beverages', label: 'Beverages' },
          { value: 'supplies', label: 'Supplies' },
          { value: 'equipment', label: 'Equipment' },
        ], required: true },
      ],
      submitLabel: 'Check Inventory',
      successMessage: 'Inventory status retrieved!',
    },
    'dietary-report': {
      title: 'Dietary Requirements Report',
      description: 'Generate a report of dietary requirements.',
      fields: [
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'summary', label: 'Summary' },
          { value: 'detailed', label: 'Detailed List' },
          { value: 'export', label: 'Export CSV' },
        ], required: true },
      ],
      submitLabel: 'Generate Report',
      successMessage: 'Dietary report generated!',
    },
    'confirm-headcount': {
      title: 'Confirm Headcount',
      description: 'Confirm the final headcount for catering.',
      fields: [
        { name: 'mealType', label: 'Meal', type: 'select', options: [
          { value: 'breakfast', label: 'Breakfast' },
          { value: 'lunch', label: 'Lunch' },
          { value: 'dinner', label: 'Dinner' },
        ], required: true },
        { name: 'confirmedCount', label: 'Confirmed Count', type: 'number', placeholder: 'Enter headcount...', required: true },
        { name: 'buffer', label: 'Buffer %', type: 'select', options: [
          { value: '5', label: '5%' },
          { value: '10', label: '10%' },
          { value: '15', label: '15%' },
        ], required: true },
      ],
      submitLabel: 'Confirm',
      successMessage: 'Headcount confirmed!',
    },
  },

  // ============ LOGISTICS COMMITTEE ============
  logistics: {
    'track-shipments': {
      title: 'Track Shipments',
      description: 'Track incoming and outgoing shipments.',
      fields: [
        { name: 'trackingNumber', label: 'Tracking Number', type: 'text', placeholder: 'Enter tracking #...', required: true },
        { name: 'carrier', label: 'Carrier', type: 'select', options: [
          { value: 'ups', label: 'UPS' },
          { value: 'fedex', label: 'FedEx' },
          { value: 'dhl', label: 'DHL' },
          { value: 'other', label: 'Other' },
        ] },
      ],
      submitLabel: 'Track',
      successMessage: 'Shipment status retrieved!',
    },
    'update-layout': {
      title: 'Update Venue Layout',
      description: 'Update the venue floor plan and layout.',
      fields: [
        { name: 'area', label: 'Area', type: 'select', options: [
          { value: 'main-hall', label: 'Main Hall' },
          { value: 'breakout-rooms', label: 'Breakout Rooms' },
          { value: 'registration', label: 'Registration Area' },
          { value: 'catering', label: 'Catering Area' },
        ], required: true },
        { name: 'change', label: 'Change Description', type: 'textarea', placeholder: 'Describe the layout change...', required: true },
      ],
      submitLabel: 'Update Layout',
      successMessage: 'Layout updated!',
    },
    'equipment-status': {
      title: 'Equipment Status',
      description: 'Update equipment status and availability.',
      fields: [
        { name: 'equipment', label: 'Equipment', type: 'text', placeholder: 'Equipment name...', required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'available', label: 'Available' },
          { value: 'in-use', label: 'In Use' },
          { value: 'maintenance', label: 'Under Maintenance' },
          { value: 'missing', label: 'Missing' },
        ], required: true },
        { name: 'location', label: 'Location', type: 'text', placeholder: 'Current location...' },
      ],
      submitLabel: 'Update Status',
      successMessage: 'Equipment status updated!',
    },
    'create-manifest': {
      title: 'Create Shipping Manifest',
      description: 'Create a new shipping manifest.',
      fields: [
        { name: 'manifestName', label: 'Manifest Name', type: 'text', placeholder: 'e.g., Event Materials - Day 1', required: true },
        { name: 'destination', label: 'Destination', type: 'text', placeholder: 'Delivery address...', required: true },
        { name: 'items', label: 'Items Description', type: 'textarea', placeholder: 'List items included...', required: true },
        { name: 'priority', label: 'Priority', type: 'select', options: [
          { value: 'standard', label: 'Standard' },
          { value: 'express', label: 'Express' },
          { value: 'urgent', label: 'Urgent' },
        ], required: true },
      ],
      submitLabel: 'Create Manifest',
      successMessage: 'Shipping manifest created!',
    },
  },

  // ============ FACILITY COMMITTEE ============
  facility: {
    'safety-check': {
      title: 'Safety Check',
      description: 'Complete a venue safety checklist.',
      fields: [
        { name: 'area', label: 'Area', type: 'select', options: [
          { value: 'main-entrance', label: 'Main Entrance' },
          { value: 'emergency-exits', label: 'Emergency Exits' },
          { value: 'electrical', label: 'Electrical Systems' },
          { value: 'fire-safety', label: 'Fire Safety Equipment' },
        ], required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'pass', label: 'Pass' },
          { value: 'fail', label: 'Fail' },
          { value: 'needs-attention', label: 'Needs Attention' },
        ], required: true },
        { name: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Inspection notes...' },
      ],
      submitLabel: 'Submit Check',
      successMessage: 'Safety check recorded!',
    },
    'venue-walkthrough': {
      title: 'Schedule Venue Walkthrough',
      description: 'Schedule a venue walkthrough session.',
      fields: [
        { name: 'date', label: 'Date', type: 'date', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
        { name: 'attendees', label: 'Attendees', type: 'text', placeholder: 'Names of participants...', required: true },
        { name: 'focus', label: 'Focus Areas', type: 'textarea', placeholder: 'Areas to review...' },
      ],
      submitLabel: 'Schedule',
      successMessage: 'Walkthrough scheduled!',
    },
    'report-issue': {
      title: 'Report Facility Issue',
      description: 'Report a facility-related issue.',
      fields: [
        { name: 'issueType', label: 'Issue Type', type: 'select', options: [
          { value: 'safety', label: 'Safety Hazard' },
          { value: 'maintenance', label: 'Maintenance Needed' },
          { value: 'cleanliness', label: 'Cleanliness' },
          { value: 'accessibility', label: 'Accessibility' },
        ], required: true },
        { name: 'location', label: 'Location', type: 'text', placeholder: 'Where is the issue?', required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Describe the issue...', required: true },
        { name: 'priority', label: 'Priority', type: 'select', options: [
          { value: 'low', label: 'Low' },
          { value: 'medium', label: 'Medium' },
          { value: 'high', label: 'High' },
          { value: 'critical', label: 'Critical' },
        ], required: true },
      ],
      submitLabel: 'Report Issue',
      successMessage: 'Issue reported!',
    },
    'room-status': {
      title: 'Update Room Status',
      description: 'Update the status of a room or area.',
      fields: [
        { name: 'room', label: 'Room/Area', type: 'text', placeholder: 'Room name...', required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'ready', label: 'Ready' },
          { value: 'in-setup', label: 'In Setup' },
          { value: 'in-use', label: 'In Use' },
          { value: 'cleanup', label: 'Cleanup Needed' },
        ], required: true },
        { name: 'capacity', label: 'Current Capacity', type: 'number', placeholder: 'Number of people...' },
      ],
      submitLabel: 'Update',
      successMessage: 'Room status updated!',
    },
  },

  // ============ MARKETING COMMITTEE ============
  marketing: {
    'schedule-post': {
      title: 'Schedule Social Post',
      description: 'Schedule a social media post.',
      fields: [
        { name: 'platform', label: 'Platform', type: 'select', options: [
          { value: 'all', label: 'All Platforms' },
          { value: 'twitter', label: 'Twitter/X' },
          { value: 'linkedin', label: 'LinkedIn' },
          { value: 'instagram', label: 'Instagram' },
          { value: 'facebook', label: 'Facebook' },
        ], required: true },
        { name: 'content', label: 'Content', type: 'textarea', placeholder: 'Post content...', required: true },
        { name: 'date', label: 'Date', type: 'date', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
      ],
      submitLabel: 'Schedule Post',
      successMessage: 'Post scheduled!',
    },
    'view-analytics': {
      title: 'View Analytics',
      description: 'View marketing analytics and metrics.',
      fields: [
        { name: 'metric', label: 'Metric', type: 'select', options: [
          { value: 'engagement', label: 'Engagement' },
          { value: 'reach', label: 'Reach' },
          { value: 'conversions', label: 'Conversions' },
          { value: 'traffic', label: 'Website Traffic' },
        ], required: true },
        { name: 'period', label: 'Time Period', type: 'select', options: [
          { value: '7d', label: 'Last 7 Days' },
          { value: '30d', label: 'Last 30 Days' },
          { value: 'all', label: 'All Time' },
        ], required: true },
      ],
      submitLabel: 'View',
      successMessage: 'Analytics loaded!',
    },
    'create-campaign': {
      title: 'Create Campaign',
      description: 'Create a new marketing campaign.',
      fields: [
        { name: 'name', label: 'Campaign Name', type: 'text', placeholder: 'Campaign name...', required: true },
        { name: 'objective', label: 'Objective', type: 'select', options: [
          { value: 'awareness', label: 'Brand Awareness' },
          { value: 'registration', label: 'Drive Registrations' },
          { value: 'engagement', label: 'Increase Engagement' },
        ], required: true },
        { name: 'startDate', label: 'Start Date', type: 'date', required: true },
        { name: 'budget', label: 'Budget', type: 'number', placeholder: '0.00' },
      ],
      submitLabel: 'Create Campaign',
      successMessage: 'Campaign created!',
    },
    'ab-test': {
      title: 'Create A/B Test',
      description: 'Set up an A/B test for marketing assets.',
      fields: [
        { name: 'testName', label: 'Test Name', type: 'text', placeholder: 'Test name...', required: true },
        { name: 'element', label: 'Element to Test', type: 'select', options: [
          { value: 'headline', label: 'Headline' },
          { value: 'cta', label: 'Call to Action' },
          { value: 'image', label: 'Image' },
          { value: 'layout', label: 'Layout' },
        ], required: true },
        { name: 'variantA', label: 'Variant A', type: 'text', placeholder: 'Describe variant A...', required: true },
        { name: 'variantB', label: 'Variant B', type: 'text', placeholder: 'Describe variant B...', required: true },
      ],
      submitLabel: 'Start Test',
      successMessage: 'A/B test created!',
    },
  },

  // ============ COMMUNICATION COMMITTEE ============
  communication: {
    'send-update': {
      title: 'Send Update',
      description: 'Send an update to stakeholders.',
      fields: [
        { name: 'audience', label: 'Audience', type: 'select', options: [
          { value: 'all', label: 'All Stakeholders' },
          { value: 'team', label: 'Team Only' },
          { value: 'sponsors', label: 'Sponsors' },
          { value: 'attendees', label: 'Attendees' },
        ], required: true },
        { name: 'subject', label: 'Subject', type: 'text', placeholder: 'Update subject...', required: true },
        { name: 'message', label: 'Message', type: 'textarea', placeholder: 'Write your update...', required: true },
      ],
      submitLabel: 'Send Update',
      successMessage: 'Update sent!',
    },
    'draft-press': {
      title: 'Draft Press Release',
      description: 'Draft a new press release.',
      fields: [
        { name: 'headline', label: 'Headline', type: 'text', placeholder: 'Press release headline...', required: true },
        { name: 'summary', label: 'Summary', type: 'textarea', placeholder: 'Brief summary...', required: true },
        { name: 'releaseDate', label: 'Release Date', type: 'date', required: true },
        { name: 'contact', label: 'Media Contact', type: 'text', placeholder: 'Contact name and email...' },
      ],
      submitLabel: 'Save Draft',
      successMessage: 'Press release draft saved!',
    },
    'email-blast': {
      title: 'Email Blast',
      description: 'Send an email to a large audience.',
      fields: [
        { name: 'list', label: 'Mailing List', type: 'select', options: [
          { value: 'all', label: 'All Subscribers' },
          { value: 'registered', label: 'Registered Attendees' },
          { value: 'vip', label: 'VIP List' },
          { value: 'sponsors', label: 'Sponsors' },
        ], required: true },
        { name: 'subject', label: 'Subject', type: 'text', placeholder: 'Email subject...', required: true },
        { name: 'content', label: 'Content', type: 'textarea', placeholder: 'Email content...', required: true },
        { name: 'sendTime', label: 'Send Time', type: 'select', options: [
          { value: 'now', label: 'Send Now' },
          { value: 'schedule', label: 'Schedule for Later' },
        ], required: true },
      ],
      submitLabel: 'Send Email',
      successMessage: 'Email blast sent!',
    },
    'stakeholder-report': {
      title: 'Stakeholder Report',
      description: 'Generate a report for stakeholders.',
      fields: [
        { name: 'reportType', label: 'Report Type', type: 'select', options: [
          { value: 'progress', label: 'Progress Update' },
          { value: 'financial', label: 'Financial Summary' },
          { value: 'metrics', label: 'Key Metrics' },
        ], required: true },
        { name: 'period', label: 'Reporting Period', type: 'select', options: [
          { value: 'weekly', label: 'This Week' },
          { value: 'monthly', label: 'This Month' },
          { value: 'custom', label: 'Custom Range' },
        ], required: true },
      ],
      submitLabel: 'Generate Report',
      successMessage: 'Stakeholder report generated!',
    },
  },

  // ============ SPONSORSHIP COMMITTEE ============
  sponsorship: {
    'add-sponsor': {
      title: 'Add Sponsor',
      description: 'Add a new sponsor to the event.',
      fields: [
        { name: 'companyName', label: 'Company Name', type: 'text', placeholder: 'Sponsor company...', required: true },
        { name: 'tier', label: 'Sponsorship Tier', type: 'select', options: [
          { value: 'platinum', label: 'Platinum' },
          { value: 'gold', label: 'Gold' },
          { value: 'silver', label: 'Silver' },
          { value: 'bronze', label: 'Bronze' },
        ], required: true },
        { name: 'contactName', label: 'Contact Name', type: 'text', placeholder: 'Primary contact...' },
        { name: 'contactEmail', label: 'Contact Email', type: 'email', placeholder: 'contact@company.com' },
        { name: 'value', label: 'Sponsorship Value', type: 'number', placeholder: '0.00' },
      ],
      submitLabel: 'Add Sponsor',
      successMessage: 'Sponsor added!',
    },
    'send-proposal': {
      title: 'Send Proposal',
      description: 'Send a sponsorship proposal.',
      fields: [
        { name: 'company', label: 'Company', type: 'text', placeholder: 'Target company...', required: true },
        { name: 'contactEmail', label: 'Contact Email', type: 'email', placeholder: 'email@company.com', required: true },
        { name: 'package', label: 'Proposed Package', type: 'select', options: [
          { value: 'platinum', label: 'Platinum Package' },
          { value: 'gold', label: 'Gold Package' },
          { value: 'silver', label: 'Silver Package' },
          { value: 'custom', label: 'Custom Package' },
        ], required: true },
        { name: 'message', label: 'Personal Message', type: 'textarea', placeholder: 'Add a personal note...' },
      ],
      submitLabel: 'Send Proposal',
      successMessage: 'Proposal sent!',
    },
    'track-deliverables': {
      title: 'Track Deliverables',
      description: 'Track sponsor deliverable completion.',
      fields: [
        { name: 'sponsor', label: 'Sponsor', type: 'text', placeholder: 'Select sponsor...', required: true },
        { name: 'deliverable', label: 'Deliverable', type: 'select', options: [
          { value: 'logo', label: 'Logo Placement' },
          { value: 'booth', label: 'Booth Setup' },
          { value: 'speaking', label: 'Speaking Slot' },
          { value: 'materials', label: 'Marketing Materials' },
        ], required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'pending', label: 'Pending' },
          { value: 'in-progress', label: 'In Progress' },
          { value: 'completed', label: 'Completed' },
        ], required: true },
      ],
      submitLabel: 'Update',
      successMessage: 'Deliverable status updated!',
    },
    'revenue-report': {
      title: 'Revenue Report',
      description: 'Generate sponsorship revenue report.',
      fields: [
        { name: 'reportType', label: 'Report Type', type: 'select', options: [
          { value: 'summary', label: 'Summary' },
          { value: 'by-tier', label: 'By Tier' },
          { value: 'by-sponsor', label: 'By Sponsor' },
        ], required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'view', label: 'View Online' },
          { value: 'pdf', label: 'Export PDF' },
          { value: 'excel', label: 'Export Excel' },
        ], required: true },
      ],
      submitLabel: 'Generate',
      successMessage: 'Revenue report generated!',
    },
  },

  // ============ SOCIAL MEDIA COMMITTEE ============
  social_media: {
    'schedule-content': {
      title: 'Schedule Content',
      description: 'Schedule social media content.',
      fields: [
        { name: 'platform', label: 'Platform', type: 'select', options: [
          { value: 'twitter', label: 'Twitter/X' },
          { value: 'instagram', label: 'Instagram' },
          { value: 'linkedin', label: 'LinkedIn' },
          { value: 'tiktok', label: 'TikTok' },
        ], required: true },
        { name: 'contentType', label: 'Content Type', type: 'select', options: [
          { value: 'post', label: 'Post' },
          { value: 'story', label: 'Story' },
          { value: 'reel', label: 'Reel/Short' },
        ], required: true },
        { name: 'caption', label: 'Caption', type: 'textarea', placeholder: 'Write caption...', required: true },
        { name: 'date', label: 'Date', type: 'date', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
      ],
      submitLabel: 'Schedule',
      successMessage: 'Content scheduled!',
    },
    'monitor-hashtags': {
      title: 'Monitor Hashtags',
      description: 'Set up hashtag monitoring.',
      fields: [
        { name: 'hashtags', label: 'Hashtags', type: 'text', placeholder: '#EventName, #Conference2024...', required: true },
        { name: 'platforms', label: 'Platforms', type: 'select', options: [
          { value: 'all', label: 'All Platforms' },
          { value: 'twitter', label: 'Twitter/X Only' },
          { value: 'instagram', label: 'Instagram Only' },
        ], required: true },
      ],
      submitLabel: 'Start Monitoring',
      successMessage: 'Hashtag monitoring enabled!',
    },
    'engagement-report': {
      title: 'Engagement Report',
      description: 'Generate social media engagement report.',
      fields: [
        { name: 'period', label: 'Time Period', type: 'select', options: [
          { value: '24h', label: 'Last 24 Hours' },
          { value: '7d', label: 'Last 7 Days' },
          { value: '30d', label: 'Last 30 Days' },
        ], required: true },
        { name: 'metrics', label: 'Metrics', type: 'select', options: [
          { value: 'all', label: 'All Metrics' },
          { value: 'reach', label: 'Reach & Impressions' },
          { value: 'engagement', label: 'Engagement Rate' },
          { value: 'growth', label: 'Follower Growth' },
        ], required: true },
      ],
      submitLabel: 'Generate Report',
      successMessage: 'Engagement report generated!',
    },
    'post-now': {
      title: 'Post Now',
      description: 'Publish content immediately.',
      fields: [
        { name: 'platform', label: 'Platform', type: 'select', options: [
          { value: 'twitter', label: 'Twitter/X' },
          { value: 'instagram', label: 'Instagram' },
          { value: 'linkedin', label: 'LinkedIn' },
        ], required: true },
        { name: 'content', label: 'Content', type: 'textarea', placeholder: 'What\'s happening?', required: true },
      ],
      submitLabel: 'Post Now',
      successMessage: 'Posted successfully!',
    },
  },

  // ============ CONTENT COMMITTEE ============
  content: {
    'review-content': {
      title: 'Review Content',
      description: 'Review submitted content.',
      fields: [
        { name: 'contentId', label: 'Content ID', type: 'text', placeholder: 'Enter content ID...', required: true },
        { name: 'decision', label: 'Decision', type: 'select', options: [
          { value: 'approve', label: 'Approve' },
          { value: 'request-changes', label: 'Request Changes' },
          { value: 'reject', label: 'Reject' },
        ], required: true },
        { name: 'feedback', label: 'Feedback', type: 'textarea', placeholder: 'Provide feedback...' },
      ],
      submitLabel: 'Submit Review',
      successMessage: 'Review submitted!',
    },
    'create-template': {
      title: 'Create Template',
      description: 'Create a new content template.',
      fields: [
        { name: 'templateName', label: 'Template Name', type: 'text', placeholder: 'Template name...', required: true },
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'email', label: 'Email' },
          { value: 'social', label: 'Social Media' },
          { value: 'document', label: 'Document' },
          { value: 'presentation', label: 'Presentation' },
        ], required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Template description...' },
      ],
      submitLabel: 'Create Template',
      successMessage: 'Template created!',
    },
    'assign-reviewer': {
      title: 'Assign Reviewer',
      description: 'Assign a reviewer to content.',
      fields: [
        { name: 'contentId', label: 'Content ID', type: 'text', placeholder: 'Content to review...', required: true },
        { name: 'reviewer', label: 'Reviewer', type: 'text', placeholder: 'Reviewer name...', required: true },
        { name: 'deadline', label: 'Review Deadline', type: 'date', required: true },
        { name: 'priority', label: 'Priority', type: 'select', options: [
          { value: 'low', label: 'Low' },
          { value: 'normal', label: 'Normal' },
          { value: 'high', label: 'High' },
        ], required: true },
      ],
      submitLabel: 'Assign',
      successMessage: 'Reviewer assigned!',
    },
    'publish': {
      title: 'Publish Content',
      description: 'Publish approved content.',
      fields: [
        { name: 'contentId', label: 'Content ID', type: 'text', placeholder: 'Content to publish...', required: true },
        { name: 'publishTo', label: 'Publish To', type: 'select', options: [
          { value: 'website', label: 'Website' },
          { value: 'app', label: 'Mobile App' },
          { value: 'both', label: 'Both' },
        ], required: true },
        { name: 'schedule', label: 'When', type: 'select', options: [
          { value: 'now', label: 'Publish Now' },
          { value: 'schedule', label: 'Schedule' },
        ], required: true },
      ],
      submitLabel: 'Publish',
      successMessage: 'Content published!',
    },
  },

  // ============ SPEAKER LIAISON COMMITTEE ============
  speaker_liaison: {
    'invite-speaker': {
      title: 'Invite Speaker',
      description: 'Send a speaker invitation.',
      fields: [
        { name: 'speakerName', label: 'Speaker Name', type: 'text', placeholder: 'Full name...', required: true },
        { name: 'email', label: 'Email', type: 'email', placeholder: 'speaker@email.com', required: true },
        { name: 'topic', label: 'Proposed Topic', type: 'text', placeholder: 'Session topic...', required: true },
        { name: 'sessionType', label: 'Session Type', type: 'select', options: [
          { value: 'keynote', label: 'Keynote' },
          { value: 'breakout', label: 'Breakout Session' },
          { value: 'workshop', label: 'Workshop' },
          { value: 'panel', label: 'Panel Discussion' },
        ], required: true },
        { name: 'message', label: 'Personal Message', type: 'textarea', placeholder: 'Invitation message...' },
      ],
      submitLabel: 'Send Invitation',
      successMessage: 'Speaker invitation sent!',
    },
    'schedule-rehearsal': {
      title: 'Schedule Rehearsal',
      description: 'Schedule a speaker rehearsal.',
      fields: [
        { name: 'speaker', label: 'Speaker', type: 'text', placeholder: 'Speaker name...', required: true },
        { name: 'date', label: 'Date', type: 'date', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'in-person', label: 'In Person' },
          { value: 'virtual', label: 'Virtual' },
        ], required: true },
        { name: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Rehearsal notes...' },
      ],
      submitLabel: 'Schedule',
      successMessage: 'Rehearsal scheduled!',
    },
    'travel-coordination': {
      title: 'Travel Coordination',
      description: 'Coordinate speaker travel arrangements.',
      fields: [
        { name: 'speaker', label: 'Speaker', type: 'text', placeholder: 'Speaker name...', required: true },
        { name: 'travelType', label: 'Arrangement Type', type: 'select', options: [
          { value: 'flight', label: 'Flight Booking' },
          { value: 'hotel', label: 'Hotel Booking' },
          { value: 'ground', label: 'Ground Transport' },
          { value: 'all', label: 'All Arrangements' },
        ], required: true },
        { name: 'arrivalDate', label: 'Arrival Date', type: 'date', required: true },
        { name: 'departureDate', label: 'Departure Date', type: 'date', required: true },
        { name: 'specialRequests', label: 'Special Requests', type: 'textarea', placeholder: 'Any special requirements...' },
      ],
      submitLabel: 'Submit Request',
      successMessage: 'Travel request submitted!',
    },
    'bio-collection': {
      title: 'Collect Speaker Bio',
      description: 'Request speaker bio and materials.',
      fields: [
        { name: 'speaker', label: 'Speaker', type: 'text', placeholder: 'Speaker name...', required: true },
        { name: 'email', label: 'Email', type: 'email', placeholder: 'speaker@email.com', required: true },
        { name: 'materials', label: 'Required Materials', type: 'select', options: [
          { value: 'bio-photo', label: 'Bio & Photo' },
          { value: 'presentation', label: 'Presentation' },
          { value: 'all', label: 'All Materials' },
        ], required: true },
        { name: 'deadline', label: 'Deadline', type: 'date', required: true },
      ],
      submitLabel: 'Send Request',
      successMessage: 'Bio request sent!',
    },
  },

  // ============ JUDGE COMMITTEE ============
  judge: {
    'assign-judges': {
      title: 'Assign Judges',
      description: 'Assign judges to submissions.',
      fields: [
        { name: 'judge', label: 'Judge', type: 'text', placeholder: 'Judge name...', required: true },
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'all', label: 'All Categories' },
          { value: 'technical', label: 'Technical' },
          { value: 'design', label: 'Design' },
          { value: 'innovation', label: 'Innovation' },
        ], required: true },
        { name: 'submissionCount', label: 'Max Submissions', type: 'number', placeholder: '10', required: true },
      ],
      submitLabel: 'Assign',
      successMessage: 'Judge assigned!',
    },
    'setup-rubrics': {
      title: 'Setup Rubrics',
      description: 'Create or edit judging rubrics.',
      fields: [
        { name: 'rubricName', label: 'Rubric Name', type: 'text', placeholder: 'Rubric name...', required: true },
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'general', label: 'General' },
          { value: 'technical', label: 'Technical' },
          { value: 'creative', label: 'Creative' },
        ], required: true },
        { name: 'criteria', label: 'Criteria Description', type: 'textarea', placeholder: 'Describe criteria and scoring...', required: true },
        { name: 'maxScore', label: 'Max Score', type: 'number', placeholder: '100', required: true },
      ],
      submitLabel: 'Save Rubric',
      successMessage: 'Rubric saved!',
    },
    'view-scores': {
      title: 'View Scores',
      description: 'View judging scores and rankings.',
      fields: [
        { name: 'category', label: 'Category', type: 'select', options: [
          { value: 'all', label: 'All Categories' },
          { value: 'technical', label: 'Technical' },
          { value: 'design', label: 'Design' },
          { value: 'innovation', label: 'Innovation' },
        ], required: true },
        { name: 'view', label: 'View', type: 'select', options: [
          { value: 'ranking', label: 'Rankings' },
          { value: 'detailed', label: 'Detailed Scores' },
          { value: 'judge-progress', label: 'Judge Progress' },
        ], required: true },
      ],
      submitLabel: 'View',
      successMessage: 'Scores loaded!',
    },
    'export-results': {
      title: 'Export Results',
      description: 'Export judging results.',
      fields: [
        { name: 'resultType', label: 'Result Type', type: 'select', options: [
          { value: 'final', label: 'Final Rankings' },
          { value: 'all-scores', label: 'All Scores' },
          { value: 'summary', label: 'Summary Report' },
        ], required: true },
        { name: 'format', label: 'Format', type: 'select', options: [
          { value: 'pdf', label: 'PDF' },
          { value: 'excel', label: 'Excel' },
          { value: 'csv', label: 'CSV' },
        ], required: true },
      ],
      submitLabel: 'Export',
      successMessage: 'Results exported!',
    },
  },

  // ============ MEDIA COMMITTEE ============
  media: {
    'upload-media': {
      title: 'Upload Media',
      description: 'Upload photos or videos.',
      fields: [
        { name: 'mediaType', label: 'Media Type', type: 'select', options: [
          { value: 'photo', label: 'Photo' },
          { value: 'video', label: 'Video' },
          { value: 'audio', label: 'Audio' },
        ], required: true },
        { name: 'album', label: 'Album/Category', type: 'select', options: [
          { value: 'general', label: 'General' },
          { value: 'speakers', label: 'Speakers' },
          { value: 'attendees', label: 'Attendees' },
          { value: 'venue', label: 'Venue' },
        ], required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Describe the media...' },
      ],
      submitLabel: 'Upload',
      successMessage: 'Media uploaded!',
    },
    'create-shot-list': {
      title: 'Create Shot List',
      description: 'Create a photography shot list.',
      fields: [
        { name: 'listName', label: 'Shot List Name', type: 'text', placeholder: 'e.g., Day 1 - Main Stage', required: true },
        { name: 'photographer', label: 'Assigned Photographer', type: 'text', placeholder: 'Photographer name...' },
        { name: 'shots', label: 'Required Shots', type: 'textarea', placeholder: 'List required shots...', required: true },
        { name: 'priority', label: 'Priority', type: 'select', options: [
          { value: 'must-have', label: 'Must Have' },
          { value: 'nice-to-have', label: 'Nice to Have' },
        ], required: true },
      ],
      submitLabel: 'Create List',
      successMessage: 'Shot list created!',
    },
    'gallery-review': {
      title: 'Gallery Review',
      description: 'Review and curate media gallery.',
      fields: [
        { name: 'album', label: 'Album', type: 'select', options: [
          { value: 'pending', label: 'Pending Review' },
          { value: 'approved', label: 'Approved' },
          { value: 'featured', label: 'Featured' },
        ], required: true },
        { name: 'action', label: 'Bulk Action', type: 'select', options: [
          { value: 'review', label: 'Start Review' },
          { value: 'approve-all', label: 'Approve All' },
          { value: 'export-selected', label: 'Export Selected' },
        ], required: true },
      ],
      submitLabel: 'Execute',
      successMessage: 'Gallery action completed!',
    },
    'export-assets': {
      title: 'Export Assets',
      description: 'Export media assets.',
      fields: [
        { name: 'assetType', label: 'Asset Type', type: 'select', options: [
          { value: 'photos', label: 'Photos' },
          { value: 'videos', label: 'Videos' },
          { value: 'all', label: 'All Assets' },
        ], required: true },
        { name: 'quality', label: 'Quality', type: 'select', options: [
          { value: 'original', label: 'Original' },
          { value: 'web', label: 'Web Optimized' },
          { value: 'social', label: 'Social Media Sizes' },
        ], required: true },
        { name: 'format', label: 'Package Format', type: 'select', options: [
          { value: 'zip', label: 'ZIP Archive' },
          { value: 'drive', label: 'Google Drive' },
          { value: 'dropbox', label: 'Dropbox' },
        ], required: true },
      ],
      submitLabel: 'Export',
      successMessage: 'Assets export started!',
    },
  },

  // ============ EVENT COMMITTEE ============
  event: {
    'update-schedule': {
      title: 'Update Schedule',
      description: 'Update the event schedule.',
      fields: [
        { name: 'session', label: 'Session', type: 'text', placeholder: 'Session name...', required: true },
        { name: 'newTime', label: 'New Time', type: 'time', required: true },
        { name: 'newDate', label: 'New Date', type: 'date' },
        { name: 'reason', label: 'Reason for Change', type: 'textarea', placeholder: 'Why is this changing...' },
      ],
      submitLabel: 'Update',
      successMessage: 'Schedule updated!',
    },
    'brief-teams': {
      title: 'Brief Teams',
      description: 'Send briefing to event teams.',
      fields: [
        { name: 'teams', label: 'Teams', type: 'select', options: [
          { value: 'all', label: 'All Teams' },
          { value: 'volunteers', label: 'Volunteers' },
          { value: 'staff', label: 'Staff' },
          { value: 'vendors', label: 'Vendors' },
        ], required: true },
        { name: 'subject', label: 'Subject', type: 'text', placeholder: 'Brief subject...', required: true },
        { name: 'message', label: 'Message', type: 'textarea', placeholder: 'Briefing content...', required: true },
      ],
      submitLabel: 'Send Brief',
      successMessage: 'Team brief sent!',
    },
    'vip-tracker': {
      title: 'VIP Tracker',
      description: 'Track VIP attendees and requirements.',
      fields: [
        { name: 'vipName', label: 'VIP Name', type: 'text', placeholder: 'VIP name...', required: true },
        { name: 'status', label: 'Status', type: 'select', options: [
          { value: 'expected', label: 'Expected' },
          { value: 'arrived', label: 'Arrived' },
          { value: 'in-meeting', label: 'In Meeting' },
          { value: 'departed', label: 'Departed' },
        ], required: true },
        { name: 'handler', label: 'Assigned Handler', type: 'text', placeholder: 'Handler name...' },
        { name: 'notes', label: 'Special Notes', type: 'textarea', placeholder: 'VIP requirements...' },
      ],
      submitLabel: 'Update',
      successMessage: 'VIP status updated!',
    },
    'run-of-show': {
      title: 'Run of Show',
      description: 'Update the run of show document.',
      fields: [
        { name: 'section', label: 'Section', type: 'select', options: [
          { value: 'opening', label: 'Opening' },
          { value: 'main', label: 'Main Program' },
          { value: 'breaks', label: 'Breaks' },
          { value: 'closing', label: 'Closing' },
        ], required: true },
        { name: 'item', label: 'Item', type: 'text', placeholder: 'Run of show item...', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
        { name: 'notes', label: 'Cues/Notes', type: 'textarea', placeholder: 'Technical cues and notes...' },
      ],
      submitLabel: 'Add to ROS',
      successMessage: 'Run of show updated!',
    },
  },

  // ============ TECHNICAL COMMITTEE ============
  technical: {
    'test-equipment': {
      title: 'Test Equipment',
      description: 'Log equipment testing results.',
      fields: [
        { name: 'equipment', label: 'Equipment', type: 'text', placeholder: 'Equipment name...', required: true },
        { name: 'location', label: 'Location', type: 'text', placeholder: 'Where is it located?', required: true },
        { name: 'status', label: 'Test Result', type: 'select', options: [
          { value: 'pass', label: 'Pass' },
          { value: 'fail', label: 'Fail' },
          { value: 'needs-adjustment', label: 'Needs Adjustment' },
        ], required: true },
        { name: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Test observations...' },
      ],
      submitLabel: 'Log Test',
      successMessage: 'Equipment test logged!',
    },
    'update-runsheet': {
      title: 'Update Technical Runsheet',
      description: 'Update the technical runsheet.',
      fields: [
        { name: 'session', label: 'Session', type: 'text', placeholder: 'Session name...', required: true },
        { name: 'cueType', label: 'Cue Type', type: 'select', options: [
          { value: 'lighting', label: 'Lighting' },
          { value: 'audio', label: 'Audio' },
          { value: 'video', label: 'Video' },
          { value: 'general', label: 'General' },
        ], required: true },
        { name: 'cue', label: 'Cue Description', type: 'textarea', placeholder: 'Describe the cue...', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
      ],
      submitLabel: 'Add Cue',
      successMessage: 'Runsheet updated!',
    },
    'tech-check': {
      title: 'Tech Check',
      description: 'Schedule or complete a tech check.',
      fields: [
        { name: 'speaker', label: 'Speaker/Presenter', type: 'text', placeholder: 'Who is presenting?', required: true },
        { name: 'room', label: 'Room', type: 'text', placeholder: 'Room name...', required: true },
        { name: 'time', label: 'Time', type: 'time', required: true },
        { name: 'requirements', label: 'Technical Requirements', type: 'textarea', placeholder: 'Laptop, presentation type, etc...' },
      ],
      submitLabel: 'Schedule',
      successMessage: 'Tech check scheduled!',
    },
    'issue-report': {
      title: 'Report Technical Issue',
      description: 'Report a technical issue.',
      fields: [
        { name: 'issueType', label: 'Issue Type', type: 'select', options: [
          { value: 'audio', label: 'Audio' },
          { value: 'video', label: 'Video' },
          { value: 'lighting', label: 'Lighting' },
          { value: 'network', label: 'Network/WiFi' },
          { value: 'equipment', label: 'Equipment Failure' },
        ], required: true },
        { name: 'location', label: 'Location', type: 'text', placeholder: 'Where is the issue?', required: true },
        { name: 'description', label: 'Description', type: 'textarea', placeholder: 'Describe the issue...', required: true },
        { name: 'severity', label: 'Severity', type: 'select', options: [
          { value: 'low', label: 'Low - Can Wait' },
          { value: 'medium', label: 'Medium - Soon' },
          { value: 'high', label: 'High - Urgent' },
          { value: 'critical', label: 'Critical - Now' },
        ], required: true },
      ],
      submitLabel: 'Report Issue',
      successMessage: 'Issue reported!',
    },
  },

  // ============ IT COMMITTEE ============
  it: {
    'check-systems': {
      title: 'Check Systems',
      description: 'Check system status and health.',
      fields: [
        { name: 'system', label: 'System', type: 'select', options: [
          { value: 'all', label: 'All Systems' },
          { value: 'wifi', label: 'WiFi Network' },
          { value: 'registration', label: 'Registration System' },
          { value: 'streaming', label: 'Streaming Platform' },
          { value: 'pos', label: 'Point of Sale' },
        ], required: true },
        { name: 'checkType', label: 'Check Type', type: 'select', options: [
          { value: 'quick', label: 'Quick Status' },
          { value: 'full', label: 'Full Diagnostic' },
        ], required: true },
      ],
      submitLabel: 'Run Check',
      successMessage: 'System check completed!',
    },
    'update-credentials': {
      title: 'Update Credentials',
      description: 'Update system credentials.',
      fields: [
        { name: 'system', label: 'System', type: 'select', options: [
          { value: 'wifi-staff', label: 'Staff WiFi' },
          { value: 'wifi-guest', label: 'Guest WiFi' },
          { value: 'admin', label: 'Admin Panel' },
          { value: 'api', label: 'API Keys' },
        ], required: true },
        { name: 'username', label: 'Username/SSID', type: 'text', placeholder: 'Username or network name...' },
        { name: 'action', label: 'Action', type: 'select', options: [
          { value: 'view', label: 'View Current' },
          { value: 'regenerate', label: 'Regenerate' },
          { value: 'update', label: 'Update' },
        ], required: true },
      ],
      submitLabel: 'Execute',
      successMessage: 'Credentials updated!',
    },
    'service-status': {
      title: 'Service Status',
      description: 'View and update service status.',
      fields: [
        { name: 'service', label: 'Service', type: 'select', options: [
          { value: 'all', label: 'All Services' },
          { value: 'event-app', label: 'Event App' },
          { value: 'website', label: 'Website' },
          { value: 'api', label: 'API' },
          { value: 'database', label: 'Database' },
        ], required: true },
        { name: 'action', label: 'Action', type: 'select', options: [
          { value: 'check', label: 'Check Status' },
          { value: 'restart', label: 'Restart' },
          { value: 'logs', label: 'View Logs' },
        ], required: true },
      ],
      submitLabel: 'Execute',
      successMessage: 'Service action completed!',
    },
    'ticket-queue': {
      title: 'Support Ticket Queue',
      description: 'Manage IT support tickets.',
      fields: [
        { name: 'filter', label: 'Filter', type: 'select', options: [
          { value: 'all', label: 'All Tickets' },
          { value: 'open', label: 'Open' },
          { value: 'in-progress', label: 'In Progress' },
          { value: 'urgent', label: 'Urgent' },
        ], required: true },
        { name: 'action', label: 'Action', type: 'select', options: [
          { value: 'view', label: 'View Queue' },
          { value: 'assign-next', label: 'Assign Next Ticket' },
          { value: 'export', label: 'Export Report' },
        ], required: true },
      ],
      submitLabel: 'Execute',
      successMessage: 'Ticket action completed!',
    },
  },
};
