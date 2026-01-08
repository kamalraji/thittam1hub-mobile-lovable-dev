import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface AcceptRequest {
  invitation_id?: string;
  token?: string;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get the authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the current user
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      console.error('Auth error:', authError);
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body: AcceptRequest = await req.json();
    const { invitation_id, token: inviteToken } = body;

    if (!invitation_id && !inviteToken) {
      return new Response(
        JSON.stringify({ error: 'Missing invitation_id or token' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`User ${user.id} attempting to accept invitation`);

    // Find the invitation
    let query = supabase
      .from('workspace_invitations')
      .select('*, workspaces(id, name)')
      .eq('status', 'PENDING');

    if (invitation_id) {
      query = query.eq('id', invitation_id);
    } else if (inviteToken) {
      query = query.eq('token', inviteToken);
    }

    const { data: invitation, error: inviteError } = await query.single();

    if (inviteError || !invitation) {
      console.error('Invitation lookup error:', inviteError);
      return new Response(
        JSON.stringify({ error: 'Invitation not found or already processed' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if invitation is for this user's email
    if (invitation.email.toLowerCase() !== user.email?.toLowerCase()) {
      console.error(`Email mismatch: invitation is for ${invitation.email}, user is ${user.email}`);
      return new Response(
        JSON.stringify({ error: 'This invitation is not for your email address' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if invitation has expired
    if (new Date(invitation.expires_at) < new Date()) {
      // Update invitation status to expired
      await supabase
        .from('workspace_invitations')
        .update({ status: 'EXPIRED' })
        .eq('id', invitation.id);

      return new Response(
        JSON.stringify({ error: 'This invitation has expired' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if user is already a member
    const { data: existingMember } = await supabase
      .from('workspace_team_members')
      .select('id')
      .eq('workspace_id', invitation.workspace_id)
      .eq('user_id', user.id)
      .eq('status', 'ACTIVE')
      .single();

    if (existingMember) {
      // Mark invitation as accepted anyway
      await supabase
        .from('workspace_invitations')
        .update({ status: 'ACCEPTED', accepted_at: new Date().toISOString() })
        .eq('id', invitation.id);

      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'You are already a member of this workspace',
          workspace_id: invitation.workspace_id 
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Add user to workspace_team_members
    const { error: memberInsertError } = await supabase
      .from('workspace_team_members')
      .insert({
        workspace_id: invitation.workspace_id,
        user_id: user.id,
        role: invitation.role,
        status: 'ACTIVE',
      });

    if (memberInsertError) {
      console.error('Error adding team member:', memberInsertError);
      return new Response(
        JSON.stringify({ error: 'Failed to join workspace' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Update invitation status
    const { error: updateError } = await supabase
      .from('workspace_invitations')
      .update({ status: 'ACCEPTED', accepted_at: new Date().toISOString() })
      .eq('id', invitation.id);

    if (updateError) {
      console.error('Error updating invitation:', updateError);
    }

    // Create a notification
    await supabase
      .from('notifications')
      .insert({
        user_id: user.id,
        title: 'Welcome to Workspace',
        message: `You have successfully joined "${invitation.workspaces?.name}" as ${invitation.role.replace(/_/g, ' ')}`,
        type: 'workspace',
        category: 'workspace',
        action_url: `/console/workspaces/${invitation.workspace_id}`,
        action_label: 'View Workspace',
      });

    console.log(`User ${user.id} joined workspace ${invitation.workspace_id}`);

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Successfully joined workspace',
        workspace_id: invitation.workspace_id,
        workspace_name: invitation.workspaces?.name 
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
