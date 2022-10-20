-- CLEANING DATA IN SQL QUERIES USING MICROSOFT SQL SERVER STUDIO--
select * from NashvilleHousing

--1. Standardize Date Format 
alter table NashvilleHousing
add SaleDateConverted date;

update NashvilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

-- 2. Populate Property Address Data 
--some address are filled in as null and so it is important to fill in that data before analysis.
--However parcel id is the same for each address 
select * from NashvilleHousing
where PropertyAddress is null
order by ParcelID

--do a self join and populate the empty address tables
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing as a 
join NashvilleHousing as b 
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

--update the table with populated property addresses 
update a --remember to use an alias instead of the table name for joins 
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing as a 
join NashvilleHousing as b 
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

--3. Breaking property address into individual columns of address, city, state
select PropertyAddress from NashvilleHousing

--split the address from the nearest delimiter which is a comma
select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
from NashvilleHousing

--now that the address has been split, update the table by creating two new columns
alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

select * from NashvilleHousing

--4. Breaking Owner Address into Address, City and State
--in addition to using substrings, we can also use the PARSENAME function.
--PARSENAME only works with fullstops, so we have to replace the comma
select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
from NashvilleHousing

--now that the address has been split, update the table by creating three new columns
alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

select * from NashvilleHousing

--5. Change Y or N to YES or NO in the Sold as Vacant column 
--to see the count distribution of values in the Sold as Vacant column 
select distinct(SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
order by SoldAsVacant

--case statement to replace y or no with yes or no
select SoldAsVacant,
	case when SoldAsVacant = 'Y' then 'Yes'
		 when SoldAsVacant = 'N' then 'No'
		 else SoldAsVacant
		 end
from NashvilleHousing

--replace the previous soldasvacant column 
update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
						end

--6. Remove Duplicates 
--to assign row numbers to rows with similar parcelid, addresses, salesprice, saledate and legal reference
select *, 
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate, 
				 LegalReference
				 order by UniqueID
				 ) row_num 
from NashvilleHousing
order by ParcelID

--create a CTE or temp table containing the original data along with the partitionby statement and delete the duplicates (rownum of 2)
with RowNumCTE as(
select *, 
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate, 
				 LegalReference
				 order by UniqueID
				 ) row_num 

from NashvilleHousing 
) 
delete from RowNumCTE
where row_num > 1

--check for outstanding duplicates 
with RowNumCTE as(
select *, 
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate, 
				 LegalReference
				 order by UniqueID
				 ) row_num 

from NashvilleHousing 
) 
select * from RowNumCTE
where row_num > 1

--6. Delete Unused Columns (only to be used in temporary database or views)
/*select * from NashvilleHousing

--to delete owner address, property address, tax district, saledate
alter table NashvilleHousing
drop column OwnerAddress, PropertyAddress, TaxDistrict, SaleDate*/
