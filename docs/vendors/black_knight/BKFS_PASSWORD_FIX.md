# BKFS Redshift Password Issue - Resolution

**Date**: 2026-01-29  
**Issue**: Password authentication failed for user "aposes"  
**Status**: ✅ Fixed - Scripts now prompt for password

---

## What Happened

The hardcoded password in the extraction scripts was incorrect/outdated:
```bash
export REDSHIFT_PASSWORD="aJ9c9Ne$3^1"  # ❌ Authentication failed
```

---

## Solution

Updated all scripts to **prompt for password** instead of hardcoding it:

```bash
# Scripts now prompt securely:
echo "Enter Redshift password for user 'aposes':"
read -s REDSHIFT_PASSWORD
export REDSHIFT_PASSWORD
```

---

## Updated Scripts

1. ✅ `scripts/bkfs/test_extraction.sh` - Now prompts for password
2. ✅ `scripts/bkfs/extract_all_bkfs_tables.sh` - Now prompts for password
3. ✅ `scripts/bkfs/test_redshift_connection.sh` - **NEW**: Quick password test script

---

## How to Use

### Option 1: Test Password First (Recommended)

```bash
# This will test your password without doing any extraction
bash scripts/bkfs/test_redshift_connection.sh
```

Enter your password when prompted. If successful, you'll see:
```
✓ Connection successful!
✓ Query successful: loanlookup has 243 rows
✓ All tests passed! Password is correct.
```

### Option 2: Set Password in Environment (For Multiple Runs)

```bash
# Set password once in your session
export REDSHIFT_PASSWORD="your_actual_password_here"

# Then run extraction without being prompted
bash scripts/bkfs/test_extraction.sh
```

### Option 3: Run Directly (Will Prompt)

```bash
# Script will prompt for password
bash scripts/bkfs/test_extraction.sh
```

---

## Next Steps

**Step 1**: Test your Redshift password:
```bash
cd /Users/aposes/Library/CloudStorage/OneDrive-PretiumPartnersLLC/System/GitHub_Repos/pretium-ai-dbt
bash scripts/bkfs/test_redshift_connection.sh
```

**Step 2**: Once password works, run test extraction:
```bash
bash scripts/bkfs/test_extraction.sh
```

**Step 3**: If successful, proceed with full extraction or create Snowflake tables

---

## Troubleshooting

### If you don't know the password:
1. Check the Redshift runbook: `docs/REDSHIFT_BKFS_RUNBOOK.md`
2. Contact IT Support: Derek Baxter (dbaxter@progressresidential.com)
3. Or try resetting your Redshift password

### If password still fails:
1. Verify VPN is connected (you already did this ✓)
2. Verify user has access to `extdata.bkfs` schema
3. Check if password needs to be reset or updated

### If you want to use the old hardcoded method:
Edit `scripts/bkfs/test_extraction.sh` and replace the password prompt section with:
```bash
export REDSHIFT_PASSWORD="your_actual_password_here"
```

---

## Security Note

✅ **Better**: Password prompting (current implementation)  
⚠️ **Acceptable**: Environment variable (`export REDSHIFT_PASSWORD=...`)  
❌ **Not recommended**: Hardcoded in scripts (risk of committing to git)

---

**Ready to test?** Run:
```bash
bash scripts/bkfs/test_redshift_connection.sh
```

