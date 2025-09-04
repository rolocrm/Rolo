# RLS Policy Rules for Supabase Integration

## 🚨 CRITICAL RULES TO FOLLOW

### 1. **Authentication Role Requirements**
- **ALWAYS** use `TO authenticated` instead of `TO public` for user-specific operations
- **NEVER** use `TO public` for INSERT/UPDATE operations that require user authentication
- **ONLY** use `TO public` for SELECT operations that should be publicly accessible

### 2. **UUID Handling in RLS Policies**
- **ALWAYS** use case-insensitive comparison: `LOWER(auth.uid()::text) = LOWER(user_id::text)`
- **NEVER** use direct comparison: `auth.uid() = user_id` (causes type mismatches)
- **ALWAYS** convert both sides to text: `auth.uid()::text = user_id::text`

### 3. **JWT Token Format Matching**
- **ALWAYS** send UUIDs as lowercase strings to match JWT format
- **JWT format**: `"sub":"a0f39310-7b92-4d76-a7ef-b34b1cb789c3"` (lowercase)
- **Code format**: `userId.uuidString.lowercased()` (lowercase)

### 4. **Authentication Headers in Requests**
- **ALWAYS** use user session token for authenticated requests
- **NEVER** use anon key for user-specific operations
- **Code pattern**:
```swift
let session = try await supabase.auth.session
request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
```

### 5. **RLS Policy Structure Template**

#### For User-Owned Records (profiles, user data):
```sql
-- INSERT: Users can create their own records
CREATE POLICY "Allow insert own record" ON table_name
FOR INSERT TO authenticated 
WITH CHECK (LOWER(auth.uid()::text) = LOWER(user_id::text));

-- SELECT: Users can view their own records
CREATE POLICY "Allow view own record" ON table_name
FOR SELECT TO authenticated 
USING (LOWER(auth.uid()::text) = LOWER(user_id::text));

-- UPDATE: Users can update their own records
CREATE POLICY "Allow update own record" ON table_name
FOR UPDATE TO authenticated 
USING (LOWER(auth.uid()::text) = LOWER(user_id::text))
WITH CHECK (LOWER(auth.uid()::text) = LOWER(user_id::text));
```

#### For Community/Collaboration Records:
```sql
-- INSERT: Community creators can add records
CREATE POLICY "Allow community creators to insert" ON table_name
FOR INSERT TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM communities 
    WHERE communities.id = table_name.community_id 
    AND LOWER(communities.created_by::text) = LOWER(auth.uid()::text)
  )
);

-- SELECT: Community members can view records
CREATE POLICY "Allow community members to view" ON table_name
FOR SELECT TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM collaborators 
    WHERE collaborators.community_id = table_name.community_id 
    AND LOWER(collaborators.user_id::text) = LOWER(auth.uid()::text)
    AND collaborators.status = 'approved'
  )
);
```

### 6. **Common Pitfalls to Avoid**

#### ❌ DON'T DO:
```sql
-- Wrong: Using public role for authenticated operations
CREATE POLICY "Wrong" ON table_name FOR INSERT TO public;

-- Wrong: Direct UUID comparison
CREATE POLICY "Wrong" ON table_name FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Wrong: Case-sensitive comparison
CREATE POLICY "Wrong" ON table_name FOR INSERT TO authenticated 
WITH CHECK (auth.uid()::text = user_id::text);
```

#### ✅ DO:
```sql
-- Correct: Using authenticated role
CREATE POLICY "Correct" ON table_name FOR INSERT TO authenticated;

-- Correct: Case-insensitive text comparison
CREATE POLICY "Correct" ON table_name FOR INSERT TO authenticated 
WITH CHECK (LOWER(auth.uid()::text) = LOWER(user_id::text));
```

### 7. **Testing Checklist**

Before deploying RLS policies:
- [ ] Test with authenticated user session token
- [ ] Verify UUID case sensitivity (lowercase)
- [ ] Check that `auth.uid()` returns expected value
- [ ] Confirm policy uses `TO authenticated` role
- [ ] Test both positive and negative cases
- [ ] Verify error messages are helpful

### 8. **Debugging Steps**

When RLS policies fail:
1. **Check JWT token**: Verify `"role":"authenticated"` not `"role":"anon"`
2. **Check UUID format**: Ensure lowercase strings match JWT `"sub"` field
3. **Check policy role**: Verify `TO authenticated` not `TO public`
4. **Check comparison**: Use `LOWER()` for case-insensitive matching
5. **Check authentication**: Ensure using session token, not anon key

### 9. **Code Implementation Pattern**

```swift
// ✅ Correct pattern for authenticated requests
func createRecord() async throws {
    let userId = try await getCurrentUser()
    
    let data: [String: Any] = [
        "user_id": userId.uuidString.lowercased(),  // ✅ Lowercase
        "other_field": "value"
    ]
    
    // ✅ Uses session token automatically via SupabaseService
    let result: [Record] = try await supabaseService.performRequest(
        endpoint: "table_name",
        method: "POST",
        body: data,
        headers: ["Prefer": "return=representation"]
    )
}
```

### 10. **Emergency Override**

If RLS policies are blocking critical operations:
```sql
-- Temporarily disable RLS for testing
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Re-enable with proper policies
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

---

**Remember**: RLS policies are security-critical. Always test thoroughly and never deploy without proper authentication and authorization checks. 