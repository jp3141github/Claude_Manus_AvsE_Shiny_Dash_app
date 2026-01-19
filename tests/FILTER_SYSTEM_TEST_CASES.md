# Filter System Test Cases

This document provides comprehensive test cases for validating the filter system functionality. Each test case includes prerequisites, steps, and expected results.

---

## Table of Contents

1. [Primary Filter Tests](#1-primary-filter-tests)
2. [Secondary Filter Tests (Chart-Level)](#2-secondary-filter-tests-chart-level)
3. [Filter Combination Tests](#3-filter-combination-tests)
4. [Input Validation Tests](#4-input-validation-tests)
5. [Edge Case Tests](#5-edge-case-tests)
6. [Error Handling Tests](#6-error-handling-tests)
7. [UI Behavior Tests](#7-ui-behavior-tests)
8. [Data Integrity Tests](#8-data-integrity-tests)
9. [Performance Tests](#9-performance-tests)
10. [State Persistence Tests](#10-state-persistence-tests)

---

## 1. Primary Filter Tests

### TC-PF-001: Model Type Filter - Single Selection
**Description:** Verify filtering by a single Model Type value
**Prerequisites:** Upload CSV with multiple Model Types (e.g., "GLM", "XGBoost", "Random Forest")
**Steps:**
1. Upload test CSV file
2. Select "GLM" from Model Type dropdown
3. Select a valid Projection Date
4. Select Event Type
5. Click Run Analysis

**Expected Result:**
- Only rows where `Model Type = "GLM"` should appear in results
- Charts should only display GLM data
- Summary tables should reflect GLM-only statistics

---

### TC-PF-002: Model Type Filter - Case Insensitivity
**Description:** Verify Model Type filter is case-insensitive
**Prerequisites:** CSV with Model Type values like "glm", "GLM", "Glm"
**Steps:**
1. Upload CSV containing mixed-case Model Type values
2. Select any Model Type from dropdown
3. Run analysis

**Expected Result:**
- Filter should match all case variations (e.g., selecting "GLM" matches "glm", "Glm", "GLM")
- No rows should be incorrectly excluded due to case mismatch

---

### TC-PF-003: Projection Date Filter - Valid Date Selection
**Description:** Verify filtering by Projection Date
**Prerequisites:** CSV with multiple Projection Dates
**Steps:**
1. Upload CSV with dates: "2025/05/31", "2025/04/30", "2025/03/31"
2. Select Model Type
3. Select "2025/05/31" from Projection Date dropdown
4. Run analysis

**Expected Result:**
- Only rows matching selected Projection Date appear
- Date displays in YYYY/MM/DD format
- Charts reflect filtered date data

---

### TC-PF-004: Projection Date Filter - Various Date Formats
**Description:** Verify system handles different input date formats
**Prerequisites:** CSV with dates in formats: "2025-05-31", "05/31/2025", "31-May-2025"
**Steps:**
1. Upload CSV with various date formats
2. Verify dates are correctly parsed in dropdown
3. Select a date and run analysis

**Expected Result:**
- All date formats should be correctly parsed
- Dropdown should display dates in standardized YYYY/MM/DD format
- Filtering should work regardless of original format

---

### TC-PF-005: Event Type Filter - "Event" Selection
**Description:** Verify filtering for Event rows
**Prerequisites:** CSV with both Event and Non-Event rows
**Steps:**
1. Upload test CSV
2. Select Model Type and Projection Date
3. Select "Event" from Event Type dropdown
4. Run analysis

**Expected Result:**
- Only rows where `Event / Non-Event = "Event"` appear
- Non-Event rows should be excluded
- Event count should match expected value

---

### TC-PF-006: Event Type Filter - "Non-Event" Selection
**Description:** Verify filtering for Non-Event rows
**Prerequisites:** CSV with both Event and Non-Event rows
**Steps:**
1. Upload test CSV
2. Select Model Type and Projection Date
3. Select "Non-Event" from Event Type dropdown
4. Run analysis

**Expected Result:**
- Only rows where `Event / Non-Event = "Non-Event"` appear
- Event rows should be excluded

---

### TC-PF-007: Event Type Filter - Case Variations
**Description:** Verify Event Type filter handles case variations
**Prerequisites:** CSV with values: "event", "EVENT", "Event", "nonevent", "NonEvent"
**Steps:**
1. Upload CSV with mixed-case event values
2. Select "Event" filter
3. Run analysis

**Expected Result:**
- All case variations of "Event" should be matched
- Normalization function should handle: "event", "EVENT", "Event", etc.

---

### TC-PF-008: Excluded Products Filter - Single Product
**Description:** Verify excluding a single product
**Prerequisites:** CSV with products: "Auto", "Home", "Life", "Health"
**Steps:**
1. Upload test CSV
2. Check "Auto" in Excluded Products checkbox group
3. Run analysis

**Expected Result:**
- No rows with `Product = "Auto"` in results
- All other products should appear
- Product dropdown in charts should not include "Auto"

---

### TC-PF-009: Excluded Products Filter - Multiple Products
**Description:** Verify excluding multiple products simultaneously
**Prerequisites:** CSV with at least 4 different products
**Steps:**
1. Upload test CSV
2. Check "Auto" and "Life" in Excluded Products
3. Run analysis

**Expected Result:**
- No rows with `Product = "Auto"` OR `Product = "Life"`
- Only remaining products appear in results and charts

---

### TC-PF-010: Excluded Products Filter - All Products Excluded
**Description:** Verify behavior when all products are excluded
**Prerequisites:** CSV with 3 products
**Steps:**
1. Upload CSV with only "Auto", "Home", "Life"
2. Exclude all three products
3. Attempt to run analysis

**Expected Result:**
- Warning or error notification should appear
- Analysis should not produce results (empty dataset)
- User should be informed no data remains

---

## 2. Secondary Filter Tests (Chart-Level)

### TC-SF-001: Product Filter - "ALL" Selection
**Description:** Verify Product filter with "ALL" selected shows all products
**Prerequisites:** Run analysis with multiple products in results
**Steps:**
1. Complete successful analysis with multiple products
2. Select "ALL" in Product dropdown for charts
3. View charts

**Expected Result:**
- All products should be displayed in charts
- Aggregated data across all products

---

### TC-SF-002: Product Filter - Specific Product
**Description:** Verify filtering charts by specific product
**Prerequisites:** Results contain multiple products
**Steps:**
1. Complete analysis
2. Select "Home" from Product dropdown
3. View charts

**Expected Result:**
- Charts should only display data for "Home" product
- Other products excluded from visualization

---

### TC-SF-003: Peril Filter - "ALL" Selection
**Description:** Verify Peril filter with "ALL" shows all perils
**Steps:**
1. Complete analysis with multiple perils
2. Select "ALL" in Peril dropdown
3. View charts

**Expected Result:**
- All perils displayed in charts
- No filtering applied

---

### TC-SF-004: Peril Filter - Specific Peril
**Description:** Verify filtering charts by specific peril
**Steps:**
1. Complete analysis
2. Select "Fire" from Peril dropdown
3. View charts

**Expected Result:**
- Only "Fire" peril data in charts
- Other perils excluded

---

### TC-SF-005: Segment Group Filter - "All" Selection
**Description:** Verify Segment Group "All" shows all segments
**Steps:**
1. Complete analysis with NIG and Non-NIG segments
2. Select "All" in Segment Group dropdown
3. View charts

**Expected Result:**
- Both NIG and Non-NIG data displayed
- No segment filtering

---

### TC-SF-006: Segment Group Filter - "NIG" Selection
**Description:** Verify filtering for NIG segment only
**Steps:**
1. Complete analysis
2. Select "NIG" from Segment Group dropdown
3. View charts

**Expected Result:**
- Only rows where `Segment = "NIG"` displayed
- Non-NIG rows excluded

---

### TC-SF-007: Segment Group Filter - "Non NIG" Selection
**Description:** Verify filtering for Non-NIG segments
**Steps:**
1. Complete analysis
2. Select "Non NIG" from Segment Group dropdown
3. View charts

**Expected Result:**
- Only rows where `Segment != "NIG"` displayed
- NIG rows excluded
- Includes rows with NA/NULL segment values

---

## 3. Filter Combination Tests

### TC-FC-001: All Primary Filters Combined
**Description:** Verify all primary filters work together (AND logic)
**Prerequisites:** CSV with varied Model Types, Dates, Events, Products
**Steps:**
1. Upload test CSV
2. Select Model Type: "GLM"
3. Select Projection Date: "2025/05/31"
4. Select Event Type: "Event"
5. Exclude Product: "Auto"
6. Run analysis

**Expected Result:**
- Results contain ONLY rows matching ALL criteria:
  - Model Type = "GLM" AND
  - Projection Date = "2025/05/31" AND
  - Event Type = "Event" AND
  - Product != "Auto"

---

### TC-FC-002: Primary + Secondary Filters Combined
**Description:** Verify primary and secondary filters stack correctly
**Steps:**
1. Run analysis with Model Type: "GLM", Event: "Event"
2. In charts, select Product: "Home"
3. Select Peril: "Fire"
4. Select Segment Group: "NIG"
5. View charts

**Expected Result:**
- Charts show: GLM + Event + Home + Fire + NIG only
- All filters applied cumulatively

---

### TC-FC-003: Filter Order Independence
**Description:** Verify filter application order doesn't affect results
**Steps:**
1. Run analysis with specific filters, note row count
2. Clear and re-upload
3. Apply same filters in different order
4. Compare results

**Expected Result:**
- Same result count regardless of filter selection order
- Data integrity maintained

---

### TC-FC-004: Excluded Products Applied Before Other Filters
**Description:** Verify product exclusion happens first
**Prerequisites:** CSV where only "Auto" has Model Type "GLM"
**Steps:**
1. Upload CSV where "Auto" product is the only one with "GLM" model
2. Exclude "Auto" product
3. Select Model Type: "GLM"
4. Run analysis

**Expected Result:**
- No results (Auto excluded, then GLM filter finds nothing)
- Appropriate warning displayed

---

### TC-FC-005: Empty Results After Filter Combination
**Description:** Verify behavior when filters result in zero rows
**Steps:**
1. Upload CSV
2. Select Model Type that exists
3. Select Projection Date that exists
4. Select Event Type that doesn't exist for that Model Type + Date combo
5. Run analysis

**Expected Result:**
- Warning notification: "No Paid/Incurred rows remain after filtering"
- Empty results handled gracefully
- Charts show no data message

---

## 4. Input Validation Tests

### TC-IV-001: Run Without Model Type Selected
**Description:** Verify validation when Model Type is empty
**Steps:**
1. Upload CSV
2. Leave Model Type unselected (empty)
3. Select Projection Date
4. Click Run Analysis

**Expected Result:**
- Error notification: "Select Model Type and Projection Date"
- Analysis does not proceed
- No partial results

---

### TC-IV-002: Run Without Projection Date Selected
**Description:** Verify validation when Projection Date is empty
**Steps:**
1. Upload CSV
2. Select Model Type
3. Leave Projection Date unselected
4. Click Run Analysis

**Expected Result:**
- Error notification: "Select Model Type and Projection Date"
- Analysis blocked

---

### TC-IV-003: Invalid Projection Date Format
**Description:** Verify rejection of unparseable dates
**Steps:**
1. Manually enter invalid date (if possible) or upload CSV with corrupted dates
2. Attempt to select/use invalid date

**Expected Result:**
- Date parsing should fail gracefully
- Error: "Projection Date not parseable or out of range"

---

### TC-IV-004: Projection Date Out of Range (Before 2000)
**Description:** Verify date range validation - too early
**Steps:**
1. Create CSV with Projection Date "1999/01/01"
2. Upload and attempt to use this date

**Expected Result:**
- Error notification about date out of range
- Date rejected (before 2000-01-01)

---

### TC-IV-005: Projection Date Out of Range (After 2100)
**Description:** Verify date range validation - too late
**Steps:**
1. Create CSV with Projection Date "2101/01/01"
2. Upload and attempt to use this date

**Expected Result:**
- Error notification about date out of range
- Date rejected (after 2100-12-31)

---

### TC-IV-006: Run Without Data Upload
**Description:** Verify validation when no CSV uploaded
**Steps:**
1. Open application fresh (no data)
2. Try to run analysis immediately

**Expected Result:**
- Error: "Upload a CSV first"
- Run button may be disabled or click shows error

---

## 5. Edge Case Tests

### TC-EC-001: Empty CSV File
**Description:** Verify handling of empty CSV (headers only)
**Steps:**
1. Create CSV with headers but no data rows
2. Upload CSV
3. Attempt to run analysis

**Expected Result:**
- Appropriate error message
- No crash or hang
- User informed file has no data

---

### TC-EC-002: Single Row CSV
**Description:** Verify handling of minimal data
**Steps:**
1. Create CSV with exactly 1 data row
2. Upload and run analysis with matching filters

**Expected Result:**
- Single row processed correctly
- Charts render (may show single point)
- Tables display single row

---

### TC-EC-003: NA/NULL Values in Filter Columns
**Description:** Verify handling of NA values in filter fields
**Prerequisites:** CSV with some NA values in Model Type, Projection Date, Event Type
**Steps:**
1. Upload CSV with NA values
2. Apply filters
3. Run analysis

**Expected Result:**
- Rows with NA in filter column should be excluded when that filter is applied
- No errors from NA comparisons
- Count reflects excluded NA rows

---

### TC-EC-004: Special Characters in Filter Values
**Description:** Verify handling of special characters
**Prerequisites:** CSV with Model Type values like "Model & Type", "Type/V2", "Model-1"
**Steps:**
1. Upload CSV with special characters in filter values
2. Select filter value with special characters
3. Run analysis

**Expected Result:**
- Special characters handled correctly
- Exact match performed
- No regex injection issues

---

### TC-EC-005: Whitespace in Filter Values
**Description:** Verify trimming of whitespace
**Prerequisites:** CSV with values like " GLM ", "GLM ", " GLM"
**Steps:**
1. Upload CSV with whitespace-padded values
2. Apply filters

**Expected Result:**
- Whitespace should be trimmed
- "GLM", " GLM ", "GLM " should all match

---

### TC-EC-006: Unicode Characters in Filter Values
**Description:** Verify Unicode support
**Prerequisites:** CSV with Model Type like "Modèle", "モデル"
**Steps:**
1. Upload CSV with Unicode values
2. Select Unicode filter value
3. Run analysis

**Expected Result:**
- Unicode values handled correctly
- No encoding errors
- Correct filtering applied

---

### TC-EC-007: Very Long Filter Values
**Description:** Verify handling of extremely long strings
**Prerequisites:** CSV with 500+ character Model Type value
**Steps:**
1. Upload CSV with very long filter value
2. Attempt to select from dropdown
3. Run analysis

**Expected Result:**
- Long value displayed (possibly truncated in UI)
- Filtering works correctly
- No buffer overflow or crash

---

### TC-EC-008: Numeric-Looking String Values
**Description:** Verify string values that look like numbers
**Prerequisites:** CSV with Model Type values: "123", "456.78", "1e10"
**Steps:**
1. Upload CSV with numeric-like Model Type values
2. Select "123" from dropdown
3. Run analysis

**Expected Result:**
- Values treated as strings, not numbers
- Exact string matching performed
- "123" doesn't match "123.0"

---

### TC-EC-009: Empty String Filter Values
**Description:** Verify handling of empty strings
**Prerequisites:** CSV with some empty string Model Type values
**Steps:**
1. Upload CSV with empty Model Type values
2. Observe dropdown options
3. Apply filters

**Expected Result:**
- Empty strings may be excluded from dropdown or shown specially
- Filtering handles empty strings appropriately

---

### TC-EC-010: Duplicate Filter Values
**Description:** Verify dropdown shows unique values
**Prerequisites:** CSV with repeated Model Type values
**Steps:**
1. Upload CSV with 1000 rows, all "GLM" Model Type
2. Check Model Type dropdown

**Expected Result:**
- Dropdown shows "GLM" only once
- No duplicates in selection list

---

## 6. Error Handling Tests

### TC-EH-001: Missing Required Column
**Description:** Verify error when required column is missing
**Steps:**
1. Create CSV without "Model Type" column
2. Upload CSV

**Expected Result:**
- Error notification: "Missing required columns: Model Type"
- Analysis blocked
- Clear indication of what's missing

---

### TC-EH-002: Column Name Variations
**Description:** Verify column alias support
**Prerequisites:** CSV with "model_type" instead of "Model Type"
**Steps:**
1. Upload CSV with alternative column names
2. Verify dropdown populates
3. Run analysis

**Expected Result:**
- System recognizes column aliases:
  - "model_type" ↔ "Model Type"
  - "projectiondate" ↔ "ProjectionDate"
  - "event_type" ↔ "Event / Non-Event"
- Filtering works correctly

---

### TC-EH-003: Graceful Skip When Filter Has No Matches
**Description:** Verify notification when filter value not found
**Steps:**
1. Upload CSV
2. Somehow select a filter value that has no matching rows
3. Run analysis

**Expected Result:**
- Warning notification: "Skipping [Filter] filter (no rows match '...')"
- Other filters still applied
- Analysis continues with remaining data

---

### TC-EH-004: Network/File Read Error During Upload
**Description:** Verify handling of upload failures
**Steps:**
1. Attempt to upload corrupted file
2. Or interrupt upload mid-way

**Expected Result:**
- Appropriate error message
- No partial state
- User can retry upload

---

### TC-EH-005: Invalid CSV Structure
**Description:** Verify handling of malformed CSV
**Steps:**
1. Create CSV with inconsistent column counts
2. Upload malformed file

**Expected Result:**
- Error message about invalid CSV format
- No crash
- Guidance to fix file

---

## 7. UI Behavior Tests

### TC-UI-001: Dropdown Auto-Population After Upload
**Description:** Verify dropdowns populate from uploaded data
**Steps:**
1. Upload CSV with 5 different Model Types
2. Check Model Type dropdown

**Expected Result:**
- Dropdown contains all 5 unique Model Types
- Sorted alphabetically
- Empty/placeholder option available

---

### TC-UI-002: Preferred Projection Date Auto-Selection
**Description:** Verify "2025/05/31" auto-selects if available
**Steps:**
1. Upload CSV containing "2025/05/31" projection date
2. Check Projection Date dropdown

**Expected Result:**
- "2025/05/31" is automatically selected
- User can change if desired

---

### TC-UI-003: Date Format Standardization
**Description:** Verify dates display in YYYY/MM/DD format
**Steps:**
1. Upload CSV with dates in various formats
2. Check Projection Date dropdown

**Expected Result:**
- All dates displayed as YYYY/MM/DD
- Consistent formatting regardless of input format

---

### TC-UI-004: Chart Control Updates After Filter Change
**Description:** Verify Product/Peril dropdowns update based on filtered data
**Steps:**
1. Run analysis with all products
2. Note Product dropdown options in charts
3. Re-run excluding some products
4. Check Product dropdown

**Expected Result:**
- Chart dropdowns reflect available data
- Excluded products not in chart Product dropdown
- Options are context-sensitive

---

### TC-UI-005: Filter Reset on New Upload
**Description:** Verify filters reset when new file uploaded
**Steps:**
1. Upload CSV, select various filters
2. Upload a different CSV

**Expected Result:**
- Filter dropdowns repopulate with new file's values
- Previous selections cleared
- No stale data

---

### TC-UI-006: Selectize Autocomplete
**Description:** Verify search/autocomplete in Model Type dropdown
**Steps:**
1. Upload CSV with many Model Types
2. Start typing in Model Type selectize input

**Expected Result:**
- Autocomplete suggestions appear
- Filtered as user types
- Can select from suggestions

---

### TC-UI-007: Checkbox Group for Product Exclusions
**Description:** Verify checkbox group functionality
**Steps:**
1. Upload CSV with multiple products
2. Check/uncheck various products
3. Verify selections persist during session

**Expected Result:**
- All products shown as checkboxes
- Multiple selections allowed
- Visual feedback for checked items

---

## 8. Data Integrity Tests

### TC-DI-001: Filter Preserves Row Data
**Description:** Verify filtered rows maintain original data
**Steps:**
1. Upload CSV, note specific row values
2. Apply filter that includes this row
3. Verify row data in results

**Expected Result:**
- All column values unchanged
- No data corruption
- Numeric precision maintained

---

### TC-DI-002: A - E Calculation After Filtering
**Description:** Verify Actual - Expected calculation correct
**Steps:**
1. Upload CSV with known Actual and Expected values
2. Run analysis
3. Verify A - E column

**Expected Result:**
- A - E = Actual - Expected for each row
- Calculation performed post-filtering
- Handles NA values appropriately

---

### TC-DI-003: Paid vs Incurred Measure Validation
**Description:** Verify only Paid/Incurred rows retained
**Steps:**
1. Upload CSV with Measure values: "Paid", "Incurred", "Other"
2. Run analysis

**Expected Result:**
- Only rows with Measure = "Paid" or "Incurred" in results
- "Other" measure rows excluded
- Notification if all rows filtered out

---

### TC-DI-004: NIG vs Non-NIG Split Accuracy
**Description:** Verify segment split is correct
**Steps:**
1. Upload CSV with known NIG/Non-NIG distribution
2. Run analysis
3. Check NIG table and Non-NIG table

**Expected Result:**
- NIG table contains only Segment = "NIG"
- Non-NIG table contains Segment != "NIG" (including NA)
- Row counts sum to total

---

### TC-DI-005: Aggregation Accuracy
**Description:** Verify aggregated values are correct
**Steps:**
1. Create small CSV with known totals
2. Run analysis
3. Verify summary statistics

**Expected Result:**
- Sum totals match manual calculation
- Averages computed correctly
- No off-by-one errors

---

## 9. Performance Tests

### TC-PF-001: Large File Filter Performance
**Description:** Verify acceptable performance with large files
**Prerequisites:** CSV with 1,000,000+ rows
**Steps:**
1. Upload large CSV
2. Apply filters
3. Measure time to run analysis

**Expected Result:**
- Analysis completes in reasonable time (<30 seconds)
- UI remains responsive
- Progress indicator shown

---

### TC-PF-002: Many Unique Filter Values
**Description:** Verify handling of many unique values
**Prerequisites:** CSV with 10,000 unique Model Types
**Steps:**
1. Upload CSV with many unique Model Types
2. Open Model Type dropdown
3. Search/scroll through options

**Expected Result:**
- Dropdown renders without hanging
- Search works efficiently
- Selection responsive

---

### TC-PF-003: Rapid Filter Changes
**Description:** Verify handling of rapid filter changes
**Steps:**
1. Quickly change filter selections multiple times
2. Run analysis

**Expected Result:**
- No race conditions
- Final selection used
- No duplicated operations

---

### TC-PF-004: Memory Usage During Filtering
**Description:** Verify no memory leaks during repeated filtering
**Steps:**
1. Upload large file
2. Run analysis 50 times with different filters
3. Monitor memory usage

**Expected Result:**
- Memory usage stable
- No continuous growth
- Garbage collection working

---

## 10. State Persistence Tests

### TC-SP-001: Event Type Preference Persistence
**Description:** Verify Event Type saved to localStorage
**Steps:**
1. Select "Event" in Event Type dropdown
2. Refresh page or close/reopen app
3. Check Event Type selection

**Expected Result:**
- "Event" selection preserved
- Restored from localStorage on reload

---

### TC-SP-002: Segment Group Preference Persistence
**Description:** Verify Segment Group saved to localStorage
**Steps:**
1. Select "NIG" in Segment Group dropdown
2. Refresh page
3. Check Segment Group selection

**Expected Result:**
- "NIG" selection preserved across sessions

---

### TC-SP-003: Preferences Cleared on Clear Storage
**Description:** Verify clearing browser storage resets preferences
**Steps:**
1. Set filter preferences
2. Clear browser localStorage
3. Reload app

**Expected Result:**
- Filter preferences reset to defaults
- No errors from missing stored values

---

### TC-SP-004: Preference Override by New Data
**Description:** Verify data-driven selections override stored preferences
**Steps:**
1. Set preference for Model Type that exists in old file
2. Upload new file without that Model Type
3. Check Model Type dropdown

**Expected Result:**
- Dropdown shows new file's Model Types
- Invalid stored preference not applied
- No error from missing value

---

## Test Data Suggestions

### Minimal Test Data (4 rows)
```csv
Model Type,ProjectionDate,Event / Non-Event,Product,Peril,Segment,Measure,Actual,Expected
GLM,2025/05/31,Event,Auto,Fire,NIG,Paid,100,90
GLM,2025/05/31,Non-Event,Home,Water,Non-NIG,Incurred,200,180
XGBoost,2025/04/30,Event,Life,Wind,NIG,Paid,150,140
XGBoost,2025/04/30,Non-Event,Health,Hail,Non-NIG,Incurred,250,240
```

### Edge Case Test Data
```csv
Model Type,ProjectionDate,Event / Non-Event,Product,Peril,Segment,Measure,Actual,Expected
glm,2025/05/31,EVENT,Auto,Fire,NIG,Paid,100,90
GLM,2025-05-31,event,Auto,Fire,NIG,Paid,100,90
 GLM ,05/31/2025,Event,Auto,Fire,NIG,Paid,100,90
,2025/05/31,Event,Auto,Fire,NIG,Paid,100,90
GLM,,Event,Auto,Fire,NIG,Paid,100,90
GLM,2025/05/31,,Auto,Fire,NIG,Paid,100,90
Model & Type,2025/05/31,Event,Auto,Fire,NIG,Paid,100,90
```

### Large Scale Test Data Generation
Use the R function in the codebase to generate test data:
```r
source("tests/testthat/helper-data.R")
test_data <- create_filter_test_data()
```

---

## Test Execution Checklist

| Test ID | Description | Pass/Fail | Notes |
|---------|-------------|-----------|-------|
| TC-PF-001 | Model Type Single Selection | | |
| TC-PF-002 | Model Type Case Insensitivity | | |
| TC-PF-003 | Projection Date Valid Selection | | |
| TC-PF-004 | Projection Date Various Formats | | |
| TC-PF-005 | Event Type "Event" | | |
| TC-PF-006 | Event Type "Non-Event" | | |
| TC-PF-007 | Event Type Case Variations | | |
| TC-PF-008 | Exclude Single Product | | |
| TC-PF-009 | Exclude Multiple Products | | |
| TC-PF-010 | Exclude All Products | | |
| TC-SF-001 | Product Filter "ALL" | | |
| TC-SF-002 | Product Filter Specific | | |
| TC-SF-003 | Peril Filter "ALL" | | |
| TC-SF-004 | Peril Filter Specific | | |
| TC-SF-005 | Segment Group "All" | | |
| TC-SF-006 | Segment Group "NIG" | | |
| TC-SF-007 | Segment Group "Non NIG" | | |
| TC-FC-001 | All Primary Filters Combined | | |
| TC-FC-002 | Primary + Secondary Combined | | |
| TC-FC-003 | Filter Order Independence | | |
| TC-FC-004 | Exclusions Before Other Filters | | |
| TC-FC-005 | Empty Results After Combination | | |
| TC-IV-001 | No Model Type Selected | | |
| TC-IV-002 | No Projection Date Selected | | |
| TC-IV-003 | Invalid Date Format | | |
| TC-IV-004 | Date Before 2000 | | |
| TC-IV-005 | Date After 2100 | | |
| TC-IV-006 | No Data Upload | | |
| TC-EC-001 | Empty CSV File | | |
| TC-EC-002 | Single Row CSV | | |
| TC-EC-003 | NA/NULL in Filter Columns | | |
| TC-EC-004 | Special Characters | | |
| TC-EC-005 | Whitespace in Values | | |
| TC-EC-006 | Unicode Characters | | |
| TC-EC-007 | Very Long Filter Values | | |
| TC-EC-008 | Numeric-Looking Strings | | |
| TC-EC-009 | Empty String Values | | |
| TC-EC-010 | Duplicate Values | | |
| TC-EH-001 | Missing Required Column | | |
| TC-EH-002 | Column Name Variations | | |
| TC-EH-003 | No Matches Skip | | |
| TC-EH-004 | Upload Failure | | |
| TC-EH-005 | Invalid CSV Structure | | |
| TC-UI-001 | Dropdown Auto-Population | | |
| TC-UI-002 | Preferred Date Auto-Selection | | |
| TC-UI-003 | Date Format Standardization | | |
| TC-UI-004 | Chart Control Updates | | |
| TC-UI-005 | Filter Reset on New Upload | | |
| TC-UI-006 | Selectize Autocomplete | | |
| TC-UI-007 | Checkbox Group | | |
| TC-DI-001 | Row Data Preserved | | |
| TC-DI-002 | A - E Calculation | | |
| TC-DI-003 | Paid/Incurred Validation | | |
| TC-DI-004 | NIG/Non-NIG Split | | |
| TC-DI-005 | Aggregation Accuracy | | |
| TC-PF-001 | Large File Performance | | |
| TC-PF-002 | Many Unique Values | | |
| TC-PF-003 | Rapid Filter Changes | | |
| TC-PF-004 | Memory Usage | | |
| TC-SP-001 | Event Type Persistence | | |
| TC-SP-002 | Segment Group Persistence | | |
| TC-SP-003 | Clear Storage | | |
| TC-SP-004 | Preference Override | | |

---

## Summary

**Total Test Cases: 55**

- Primary Filter Tests: 10
- Secondary Filter Tests: 7
- Filter Combination Tests: 5
- Input Validation Tests: 6
- Edge Case Tests: 10
- Error Handling Tests: 5
- UI Behavior Tests: 7
- Data Integrity Tests: 5
- Performance Tests: 4
- State Persistence Tests: 4
