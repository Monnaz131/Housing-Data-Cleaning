
SELECT *
FROM Projects..NashvilleHousing



-- CONVERT SALE DATE


-- Add column with converted Sale Date
ALTER TABLE NashvilleHousing
Add DateSold DATE

UPDATE NashvilleHousing
SET DateSold = CONVERT(date, SaleDate)

-- Drop original Sale Date Column
ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate




-- POPULATE NULL-VALLUE PROPERTY ADDRESS

-- Join table by itself to see if null-value Property Addresses can be populated by using Parcel ID
SELECT a.UniqueID, a.ParcelID, a.PropertyAddress, b.UniqueID, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Projects..NashvilleHousing a
JOIN Projects..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null
order by a.ParcelID

-- Update Table to populate Property Address where possible
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Projects..NashvilleHousing a
JOIN Projects..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- Check to see if null values remain
SELECT PropertyAddress
FROM Projects..NashvilleHousing
Where PropertyAddress is null



-- SPLIT PROPERTY ADDRESS AND ADD CITY COLUMN

-- Create new columns for Address and City
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) AS City
FROM Projects..NashvilleHousing

-- Add columns to table
ALTER TABLE NashvilleHousing
ADD Address nvarchar(255)

UPDATE NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD City nvarchar(255)

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))



-- SPLIT OWNER ADDRESS AND ADD OWNERSPLITADDRESS, OWNERSPLITCITY, AND OWNERSPLITSTATE

-- Create new columns for address, city, and state
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2) AS OwnerSplitCity,
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2) AS OwnerSplitState
FROM Projects..NashvilleHousing

-- Add new columns to the table
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1)



-- MODIFY SOLD AS VACANT TO YES AND NO

-- Change values for Sold As Vacant and update table
SELECT DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM Projects..NashvilleHousing
group by SoldAsVacant

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM Projects..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END



-- REMOVING UNUSABLE DATA

-- Remove duplicate rows
-- Find the duplicates using a CTE
WITH RowNumber AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						 PropertyAddress,
						 SalePrice,
						 DateSold,
						 LegalReference
						 ORDER BY UniqueID
		) RowNum
	FROM Projects..NashvilleHousing
)



-- Delete duplicates from table
DELETE
FROM RowNumber
WHERE RowNum > 1



-- Drop unusable columns

ALTER TABLE Projects..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict



-- Drop unusable rows

DELETE
FROM Projects..NashvilleHousing
WHERE Acreage is null AND LandValue is null AND BuildingValue is null AND TotalValue is null




-- CREATE VIEWS FOR DATA THAT NEEDS INSPECTION

-- Missing Owner Names
USE Projects
GO
CREATE VIEW MissingOwnerNames AS
SELECT *
FROM Projects..NashvilleHousing
WHERE OwnerName is null

-- Missing Year Built
USE Projects
GO
CREATE VIEW MissingYearBuilt AS
SELECT *
FROM Projects..NashvilleHousing
WHERE YearBuilt is null

-- Missing House Descriptions
USE Projects
GO
CREATE VIEW MissingHouseDescriptions AS
SELECT *
FROM Projects..NashvilleHousing
WHERE Bedrooms is null