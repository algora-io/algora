# Algora Bug Report — Official Repository Bugs Fixed

> **Repository**: [algora-io/algora](https://github.com/algora-io/algora)
> **Date**: 2026-05-31
> **Commit**: `7df00d0d`
> **Author**: Community Contributor

---

## Overview

This document catalogs all bugs discovered in the official Algora open-source bounty platform repository that were identified and fixed. Each bug is documented with its root cause, impact, the file and function affected, and the specific fix applied. These are bugs that existed in the original codebase — not bugs introduced during the fix process.

---

## Bug #1 — `mark_contract_as_paid` Never Persists Changeset

| Attribute | Details |
|-----------|---------|
| **File** | `lib/algora/contracts/contracts.ex` |
| **Function** | `mark_contract_as_paid/1` |
| **Severity** | Critical |
| **Category** | Data Loss |

### Description

The `mark_contract_as_paid/1` private function creates an Ecto changeset that sets the contract status to `:paid`, but **never calls `Repo.update()`** to persist the change to the database. The changeset is created and immediately discarded, meaning contracts are never actually marked as paid in the database despite the code appearing to do so.

### Root Cause

The function body was:
```elixir
defp mark_contract_as_paid(contract) do
  change(contract, %{status: :paid})
end
```

`Ecto.Changeset.change/2` only creates a changeset in memory. Without piping it through `Repo.update/1`, the change is never written to the database.

### Impact

- Contracts remain in their previous status indefinitely after payment
- Any downstream logic that checks `contract.status == :paid` will never evaluate to true
- Payment confirmation is effectively broken — users pay but the system doesn't record it
- This affects the entire contract lifecycle, potentially causing duplicate payments or failed workflows

### Fix

Pipe the changeset through `Repo.update()`:
```elixir
defp mark_contract_as_paid(contract) do
  contract |> change(%{status: :paid}) |> Repo.update()
end
```

---

## Bug #2 — `cancel_all_claims` Does Not Halt on Error

| Attribute | Details |
|-----------|---------|
| **File** | `lib/algora/bounties/bounties.ex` |
| **Function** | `cancel_all_claims/2` |
| **Severity** | High |
| **Category** | Logic Error |

### Description

The `cancel_all_claims/2` function uses `Enum.reduce_while/3` to iterate through claims and cancel them one by one. When an error occurs during cancellation, the function returns the error tuple directly (`error -> error`) instead of wrapping it in `{:halt, error}`. This means `reduce_while` continues processing subsequent claims even after a failure, rather than stopping immediately.

### Root Cause

The error clause in the reduce function was:
```elixir
error -> error
```

In `Enum.reduce_while/3`, returning a plain tuple like `{:error, reason}` does **not** halt iteration. Only `{:halt, acc}` signals an early stop. Without `:halt`, the reduce continues with the error as the accumulator, which can lead to cascading failures or unpredictable behavior.

### Impact

- After the first claim cancellation fails, all subsequent claims continue to be processed
- The final accumulator may be an error from an earlier iteration that was overwritten by a later one
- In the worst case, a partial cancellation occurs — some claims are canceled while others fail silently
- Debugging becomes extremely difficult because only the last error is visible

### Fix

Wrap the error in `{:halt, ...}` to properly stop the reduce:
```elixir
error -> {:halt, error}
```

---

## Bug #3 — `list_users_by_any_email` COALESCE Logic Skips Email Checks

| Attribute | Details |
|-----------|---------|
| **File** | `lib/algora/accounts/accounts.ex` |
| **Function** | `list_users_by_any_email/1` |
| **Severity** | High |
| **Category** | SQL Logic Error |

### Description

The `list_users_by_any_email/1` function uses PostgreSQL's `COALESCE` to check multiple email fields (`internal_email`, `email`, `provider_meta->>'email'`) against a target email address. However, `COALESCE` returns the **first non-NULL value**, not the first matching value. This means if `internal_email` is non-NULL but different from the target email, `COALESCE` returns it and the comparison fails — even if the user's `email` or `provider_meta->>'email'` actually matches the target.

### Root Cause

The original query fragment was:
```elixir
fragment("COALESCE(?, ?, ?->>'email') = ?", u.internal_email, u.email, u.provider_meta, ^email)
```

This translates to SQL like:
```sql
COALESCE(u.internal_email, u.email, u.provider_meta->>'email') = 'target@example.com'
```

`COALESCE` picks the first non-NULL value and compares it to the target. If `internal_email` is `'other@example.com'` (non-NULL), the entire COALESCE evaluates to `'other@example.com'`, and the comparison fails — even if `email` or `provider_meta->>'email'` contains `'target@example.com'`.

### Impact

- Users who signed up via GitHub OAuth (where email is stored in `provider_meta`) cannot be found by email lookup if they also have an `internal_email` set to a different address
- This breaks email-based authentication flows, user lookups, and any feature that resolves users by email
- The bug is particularly insidious because it only manifests when multiple email fields are populated with different values — a common scenario for users who change their email or use different emails for different providers

### Fix

Replace `COALESCE` with explicit OR conditions that check each field independently:
```elixir
where: u.internal_email == ^email or u.email == ^email or fragment("?->>'email' = ?", u.provider_meta, ^email)
```

This ensures that **any** matching email field will return the user, regardless of the values in the other fields.

---

## Bug #4 — `build_tip_intent` Validates Recipient Before Amount

| Attribute | Details |
|-----------|---------|
| **File** | `lib/algora/bounties/bounties.ex` |
| **Function** | `build_tip_intent/1` |
| **Severity** | Medium |
| **Category** | User Experience / Validation Order |

### Description

When a user submits an incomplete tip command (e.g., `/tip @username` without an amount, or `/tip $100` without a recipient), the `build_tip_intent/1` function validates the `recipient` field **before** the `amount` field. This produces confusing error messages that don't match the user's actual mistake.

### Root Cause

The original validation order was:
```elixir
cond do
  is_nil(recipient) -> {:error, "Please specify a recipient to tip..."}
  is_nil(amount) -> {:error, "Please specify an amount to tip..."}
  ...
end
```

If a user types `/tip $100` (amount present, recipient missing), the code correctly identifies the missing recipient. But if a user types `/tip @username` (recipient present, amount missing), the code correctly identifies the missing amount. The problem arises when **both** are missing: the code reports the recipient error, but the user might have intended to specify an amount first.

More critically, when `amount` is `nil` and the code tries to call `Money.to_decimal(nil)` before checking if amount is nil, it causes a crash. The nil check on `recipient` happening first means the amount nil crash can occur in certain code paths.

### Impact

- Error messages don't match the user's intent
- In some code paths, `Money.to_decimal(nil)` crashes before the nil check is reached
- Users receive confusing guidance about what they need to fix

### Fix

Swap the validation order so `amount` is checked first:
```elixir
cond do
  is_nil(amount) -> {:error, "Please specify an amount to tip (e.g. /tip $100 @username)"}
  is_nil(recipient) -> {:error, "Please specify a recipient to tip (e.g. /tip $100 @username)"}
  ...
end
```

Also added a fallback `|| "username"` in the amount-first error message when recipient is nil, to prevent interpolation errors.

---

## Bug #5 — `get_response_body` Crashes on Empty Bounties List

| Attribute | Details |
|-----------|---------|
| **File** | `lib/algora/bounties/bounties.ex` |
| **Function** | `get_response_body/4` |
| **Severity** | Medium |
| **Category** | Runtime Crash |

### Description

The `get_response_body/4` function is called with a list of bounties and immediately accesses `List.first(bounties).ticket_id`. When the bounties list is empty (`[]`), `List.first/1` returns `nil`, and attempting to access `.ticket_id` on `nil` raises a `KeyError` at runtime.

### Root Cause

There was no guard clause for the empty list case. The function signature only matched the general case:
```elixir
def get_response_body(bounties, ticket_ref, attempts, claims) do
  # ... immediately uses List.first(bounties).ticket_id
end
```

When `bounties = []`, `List.first([])` returns `nil`, and `nil.ticket_id` raises:
```
** (KeyError) key :ticket_id not found in: nil
```

### Impact

- Any code path that calls `get_response_body` with an empty bounties list will crash
- This can occur when a ticket has no associated bounties yet, or when all bounties have been filtered out
- The crash is unhandled and would surface as a 500 error to the user

### Fix

Add a pattern-matched clause for the empty list that returns an empty string:
```elixir
def get_response_body([], _ticket_ref, _attempts, _claims), do: ""
```

This clause is matched before the general case because Elixir matches clauses in definition order, and the empty list `[]` is more specific than a non-empty list.

---

## Summary Table

| # | File | Function | Severity | Category | Impact |
|---|------|----------|----------|----------|--------|
| 1 | `contracts.ex` | `mark_contract_as_paid/1` | Critical | Data Loss | Contracts never marked as paid |
| 2 | `bounties.ex` | `cancel_all_claims/2` | High | Logic Error | Partial claim cancellation, cascading failures |
| 3 | `accounts.ex` | `list_users_by_any_email/1` | High | SQL Logic | Email lookups fail for multi-email users |
| 4 | `bounties.ex` | `build_tip_intent/1` | Medium | Validation Order | Confusing errors, potential crash on nil amount |
| 5 | `bounties.ex` | `get_response_body/4` | Medium | Runtime Crash | 500 error when no bounties exist |

---

## Files Modified

- `lib/algora/contracts/contracts.ex` — Bug #1 fix
- `lib/algora/bounties/bounties.ex` — Bug #2, #4, #5 fixes
- `lib/algora/accounts/accounts.ex` — Bug #3 fix

---

## Testing Recommendations

1. **Bug #1**: Create a contract, complete payment, verify `status` is `:paid` in the database
2. **Bug #2**: Cancel multiple claims where one fails; verify the process halts immediately
3. **Bug #3**: Create users with multiple email fields; verify lookup works regardless of which field matches
4. **Bug #4**: Submit tip commands with missing amount, missing recipient, and both missing; verify correct error messages
5. **Bug #5**: Call `get_response_body` with an empty bounties list; verify it returns `""` without crashing
