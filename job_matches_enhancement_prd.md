# Job Matches Enhancement PRD

## Overview

Enhance the job matching system in `lib/algora_web/live/org/job_live.ex` to provide better candidate privacy, accurate match counting, improved matching criteria, and visual enhancement with GitHub contribution heatmaps.

## Background

Currently, the job matching system in `lib/algora_web/live/org/job_live.ex` has several limitations:
1. Matches show full user information (avatar, name, handle) which may not be appropriate for privacy
2. Match counts are artificially limited (15-50 matches) rather than showing actual match numbers
3. Matching criteria doesn't properly validate user email availability
4. Missing visual contribution heatmaps that provide valuable candidate assessment data

## Goals

1. **Anonymize Matches**: Protect candidate privacy by anonymizing user information in match cards
2. **Accurate Match Counting**: Display real match counts instead of arbitrary limits
3. **Enhanced Matching Criteria**: Improve matching logic to include email validation
4. **Visual Enhancement**: Add GitHub contribution heatmaps for better candidate evaluation

## Requirements

### 1. Anonymized Match Display

**Current State:**
- Matches display full user avatar, name, and GitHub handle
- All user information is visible in match cards

**Required Changes:**
- Replace user avatar with a gray circle (`bg-muted` background)
- Replace user name and handle with "Anonymous user" text
- Apply `blur-sm` CSS class to anonymized text for visual indication
- Maintain country flag display if available
- Keep contribution data and tech stack information visible

**Technical Implementation:**
```heex
<!-- Current -->
<.avatar class="h-12 w-12 rounded-full">
  <.avatar_image src={@user.avatar_url} alt={@user.name} />
</.avatar>
<span class="font-semibold">{@user.name}</span>

<!-- Anonymized -->
<div class="h-12 w-12 rounded-full bg-muted"></div>
<span class="font-semibold blur-sm">Anonymous user</span>
```

### 2. Accurate Match Counting

**Current State:**
- `Algora.Cloud.truncate_matches/2` limits matches to 15 for non-subscribed orgs
- `Algora.Cloud.count_matches/1` returns fixed limits (50-100)
- Display shows truncated count, not actual available matches

**Required Changes:**
- Modify `get_job_matches/1` in `Algora.Settings` to count all available matches
- Update match counting logic to return actual numbers instead of arbitrary limits
- Display format: "X matches found" where X is the real count
- Maintain existing subscription-based access controls for viewing matches

**Technical Implementation:**
```elixir
# In Algora.Settings.get_job_matches/1
def get_job_matches(job) do
  total_matches = count_all_matches(job)  # New function
  available_matches = get_subscription_limited_matches(job)  # Existing logic
  
  %{
    total_count: total_matches,
    matches: available_matches
  }
end

# New helper function
defp count_all_matches(job) do
  [
    tech_stack: job.tech_stack,
    email_required: true,  # New criteria
    count_only: true
  ]
  |> Algora.Cloud.list_top_matches()
  |> length()
end
```

### 3. Enhanced Matching Criteria

**Current State:**
- Matching logic in `Algora.Cloud.list_top_matches/1` doesn't validate email availability
- Users without email addresses may be included in matches

**Required Changes:**
- Add email validation to matching criteria
- A user should be considered a match if they have either:
  - `user.email` field populated, OR
  - `user.provider_meta["email"]` field populated
- Update matching query to include this email check
- Maintain existing tech stack matching logic

**Technical Implementation:**
```elixir
# In Algora.Cloud.list_top_matches/1
def list_top_matches(opts) do
  # ... existing query setup ...
  
  query =
    query
    |> where([u], not is_nil(u.email) or fragment("? IS NOT NULL", u.provider_meta["email"]))
    # ... rest of existing filters ...
end
```

### 4. GitHub Contribution Heatmaps

**Current State:**
- `lib/algora_cloud/live/candidates_live.ex` has heatmap implementation
- Heatmaps are stored in `user_heatmaps` table
- Async sync functionality exists via `AlgoraCloud.Profiles.sync_heatmap_by/1`

**Required Changes:**
- Add heatmap display to match cards in `job_live.ex`
- Implement similar heatmap component as in `candidates_live.ex`
- Add async heatmap syncing when socket connects for users without heatmap data
- Display 17-week contribution grid with color-coded activity levels

**Technical Implementation:**

1. **Update socket assigns in `assign_applicants/1`:**
```elixir
defp assign_applicants(socket) do
  # ... existing code ...
  
  # Fetch heatmaps for all developers
  heatmaps_map =
    developers
    |> Enum.map(& &1.id)
    |> AlgoraCloud.Profiles.list_heatmaps()
    |> Map.new(fn heatmap -> {heatmap.user_id, heatmap.data} end)
  
  # Trigger async sync for missing heatmaps
  missing_heatmap_users = 
    developers
    |> Enum.reject(&Map.has_key?(heatmaps_map, &1.id))
  
  if connected?(socket) and length(missing_heatmap_users) > 0 do
    enqueue_heatmap_sync(missing_heatmap_users)
  end
  
  socket
  |> assign(:heatmaps_map, heatmaps_map)
  # ... rest of existing assigns ...
end

defp enqueue_heatmap_sync(users) do
  Task.start(fn ->
    for user <- users do
      AlgoraCloud.Profiles.sync_heatmap_by(id: user.id)
    end
  end)
end
```

2. **Add heatmap component to match cards:**
```heex
<!-- In match_card function -->
<div :if={@heatmaps_map[@user.id]} class="mt-4">
  <.heatmap_display user_id={@user.id} heatmap_data={@heatmaps_map[@user.id]} />
</div>
```

3. **Implement heatmap component (based on candidates_live.ex):**
```heex
defp heatmap_display(assigns) do
  ~H"""
  <div class="mt-4">
    <div class="flex items-center justify-between mb-2">
      <div class="text-xs text-muted-foreground uppercase font-semibold">
        {get_in(@heatmap_data, ["totalContributions"])} contributions in the last year
      </div>
    </div>
    <div class="grid grid-cols-[repeat(17,1fr)] gap-1">
      <%= for week <- get_in(@heatmap_data, ["weeks"]) |> Enum.take(-17) do %>
        <div class="grid grid-rows-7 gap-1">
          <%= for day <- week["contributionDays"] do %>
            <div
              class={"h-3 w-3 rounded-sm #{get_contribution_color(day["contributionCount"])}"}
              title={"#{day["contributionCount"]} contributions on #{format_date(day["date"])}"}
            >
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  </div>
  """
end

defp get_contribution_color(count) do
  cond do
    count == 0 -> "bg-muted/50"
    count in 1..5 -> "bg-success-400/40"
    count in 6..10 -> "bg-success-400/50"
    count in 11..15 -> "bg-success-400/70"
    count in 16..20 -> "bg-success-400/90"
    true -> "bg-success-400"
  end
end
```

## Implementation Plan

### Phase 1: Anonymization and Match Counting
1. Update `match_card/1` function to display anonymized user information
2. Modify `Algora.Settings.get_job_matches/1` to return actual match counts
3. Update UI to display real match numbers
4. Test anonymization with different user types and subscription levels

### Phase 2: Enhanced Matching Criteria
1. Update `Algora.Cloud.list_top_matches/1` to include email validation
2. Add database query filters for email requirements
3. Update matching logic to check both `user.email` and `user.provider_meta["email"]`
4. Test matching accuracy with email filtering

### Phase 3: Heatmap Integration
1. Add heatmap data fetching to `assign_applicants/1`
2. Implement async heatmap syncing for missing data
3. Add heatmap component to match cards
4. Test heatmap display and async syncing functionality

### Phase 4: Testing and Optimization
1. Performance testing with large match sets
2. UI/UX testing for anonymized cards
3. Async operation monitoring for heatmap syncing
4. Cross-browser compatibility testing

## Success Metrics

1. **Privacy Protection**: All match cards show anonymized information for non-subscribed viewers
2. **Accurate Counts**: Match counts reflect actual available candidates, not artificial limits
3. **Better Matching**: Only users with email addresses are included in matches
4. **Enhanced UX**: Heatmaps provide visual contribution data for better candidate assessment
5. **Performance**: Async heatmap syncing doesn't impact page load times

## Technical Considerations

### Database Impact
- Heatmap syncing may increase database load
- Consider implementing rate limiting for async sync operations
- Monitor performance of email filtering queries

### Caching Strategy
- Cache heatmap data to reduce GitHub API calls
- Implement TTL for heatmap data (suggested: 24 hours)
- Cache match counts to improve performance

### Error Handling
- Handle GitHub API rate limits gracefully
- Fallback display when heatmap data is unavailable
- Graceful degradation if anonymization fails

### Security Considerations
- Ensure anonymization cannot be bypassed client-side
- Validate subscription status server-side for match access
- Protect GitHub API tokens used for heatmap syncing

## Files to Modify

1. **`lib/algora_web/live/org/job_live.ex`** - Main implementation file
2. **`lib/algora/settings/settings.ex`** - Match counting logic
3. **`lib/algora_cloud/algora_cloud.ex`** - Matching criteria enhancement
4. **`lib/algora_cloud/profiles.ex`** - Heatmap syncing (if needed)

## Dependencies

- Existing `AlgoraCloud.Profiles` module for heatmap functionality
- `user_heatmaps` database table
- GitHub GraphQL API access for contribution data
- Existing subscription and authentication systems

## Rollout Strategy

1. **Development**: Implement features in feature branch
2. **Staging**: Test with sample job postings and user data
3. **Gradual Rollout**: Deploy to subset of organizations initially
4. **Full Deployment**: Roll out to all organizations after validation
5. **Monitoring**: Track performance metrics and user feedback

## Future Enhancements

1. **Advanced Anonymization**: Different levels of anonymization based on subscription tiers
2. **Enhanced Heatmaps**: Additional metrics like PR review activity, issue contributions
3. **Real-time Updates**: Live updating of match counts and heatmap data
4. **Export Functionality**: Allow exporting of match data for subscribed organizations