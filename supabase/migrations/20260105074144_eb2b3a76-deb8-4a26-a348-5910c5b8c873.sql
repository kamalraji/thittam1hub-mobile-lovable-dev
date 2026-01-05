-- Disable the trigger that requires authentication
ALTER TABLE public.workspaces DISABLE TRIGGER set_workspace_organizer_before_insert;

-- Create L4 Team workspaces under each L3 Committee
INSERT INTO public.workspaces (
  name,
  event_id,
  organizer_id,
  parent_workspace_id,
  workspace_type,
  department_id,
  status
) VALUES 
(
  'Event Coordination Team',
  'cad90197-8084-44db-befc-4984495ac99c',
  'e9edf3b4-c5f6-4d67-937f-750da1b13a1a',
  '0f687000-d522-48d0-bca9-4f1efc52df8a',
  'TEAM',
  NULL,
  'active'
),
(
  'Logistics Team',
  'cad90197-8084-44db-befc-4984495ac99c',
  'e9edf3b4-c5f6-4d67-937f-750da1b13a1a',
  'fc40f431-e6ae-43c9-8157-87587c8ce97f',
  'TEAM',
  NULL,
  'active'
),
(
  'Marketing Team',
  'cad90197-8084-44db-befc-4984495ac99c',
  'e9edf3b4-c5f6-4d67-937f-750da1b13a1a',
  '2d14281d-be17-4430-bc35-8dd32e5316ec',
  'TEAM',
  NULL,
  'active'
),
(
  'Social Media Team',
  'cad90197-8084-44db-befc-4984495ac99c',
  'e9edf3b4-c5f6-4d67-937f-750da1b13a1a',
  'd261115d-0a25-4965-aa9b-81e7327dff35',
  'TEAM',
  NULL,
  'active'
);

-- Re-enable the trigger
ALTER TABLE public.workspaces ENABLE TRIGGER set_workspace_organizer_before_insert;