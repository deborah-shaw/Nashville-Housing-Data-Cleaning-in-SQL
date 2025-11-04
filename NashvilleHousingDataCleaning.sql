/*
Cleaning Data in SQL Queries

Database: Microsoft SQL Server

Link to dataset: https://github.com/deborah-shaw/Nashville-Housing-Data-Cleaning-in-SQL/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx
*/

SELECT * FROM NashvilleHousingData..NashvilleHousing;

-------------------------------------------------------------------------------------------------------------------------------

-- Standardize Data Format

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM NashvilleHousingData..NashvilleHousing;

UPDATE NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate);

-- -- If doesn't work, do below

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);


-- Populate Property Address Data Using Self Join

SELECT *
FROM NashvilleHousingData..NashvilleHousing
WHERE PropertyAddress IS NULL

-- -- Below 2 queries found the same 35 rows
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousingData..NashvilleHousing AS a
JOIN NashvilleHousingData..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
WHERE a.PropertyAddress IS NOT NULL
	AND b.PropertyAddress IS NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingData..NashvilleHousing AS a
JOIN NashvilleHousingData..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS  NULL

UPDATE a
SET PropertyAddress = b.PropertyAddress
FROM NashvilleHousingData..NashvilleHousing AS a
JOIN NashvilleHousingData..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Breaking Out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousingData..NashvilleHousing

SELECT 
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousingData..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- -- Now let's do Owner's address
SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold As Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousingData..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);

SELECT 
	SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
FROM NashvilleHousingData..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = (
					CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END
					);

---------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS
(
	SELECT *,
			ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted, LegalReference ORDER BY UniqueID) AS row_num
	FROM NashvilleHousingData..NashvilleHousing
)
-- SELECT *
DELETE
FROM RowNumCTE
WHERE row_num > 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM NashvilleHousingData..NashvilleHousing;

ALTER TABLE NashvilleHousingData..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate, TaxDistrict;

