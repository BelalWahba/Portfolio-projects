USE Cleaning;



SELECT * FROM houses


-- Standardize Date Format
-- we will add a new date column and add the fixed date to it then we will drop the old columns later on 

ALTER TABLE houses
ADD SaleDateFixed Date;

UPDATE houses
SET SaleDateFixed = CONVERT(DATE,SaleDate);

SELECT SaleDate,SaleDateFixed
FROM houses


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data


-- the theory behind this query is that there might be a house that has been sold multible times and it has the property address on one of the entries
-- so we join the table based of the parcelid where the uniqueid is different to assure that we will only get unique entries of the property we also add the legal reference 
-- to further make sure that there is no duplicated entries then we will set the property address to the null values of the missing ones

SELECT * 
FROM houses a
join houses b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
and a.LegalReference <> b.LegalReference
where a.PropertyAddress IS NULL and b.PropertyAddress IS NOT NULL

--

SELECT a.PropertyAddress,b.PropertyAddress
FROM houses a
join houses b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
and a.LegalReference <> b.LegalReference
where a.PropertyAddress IS NULL and b.PropertyAddress IS NOT NULL

--the update statement

UPDATE a
SET a.PropertyAddress=b.PropertyAddress
FROM houses a
join houses b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
and a.LegalReference <> b.LegalReference
where a.PropertyAddress IS NULL and b.PropertyAddress IS NOT NULL


-- from further looking at the data we can conclude that there is a very high chance that both property address and the owner address share the same address but for the sake of simplicity we will
-- not further populate the data 

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- The idea is to replace the , with . so that we use parsename and break down the column based on the delimiter

SELECT houses.PropertyAddress 
FROM houses

SELECT PropertyAddress, PARSENAME(REPLACE(PropertyAddress, ',', '.'),2) PropertyAddressFixed, PARSENAME(REPLACE(PropertyAddress, ',', '.'),1) PropertyCity 
FROM houses

SELECT houses.OwnerAddress ,PARSENAME(REPLACE(OwnerAddress,',','.'),3) OwnerAddressFixed,PARSENAME(REPLACE(OwnerAddress,',','.'),2) OwnerCity,PARSENAME(REPLACE(OwnerAddress,',','.'),1) OwnerState
FROM houses

Alter table houses
ADD PropertyAddressFixed nvarchar(255),
PropertyCity nvarchar(255),
OwnerAddressFixed nvarchar(255),
OwnerCity nvarchar(255),
OwnerState nvarchar(255);


UPDATE houses
SET PropertyAddressFixed = PARSENAME(REPLACE(PropertyAddress, ',', '.'),2) , PropertyCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'),1), OwnerAddressFixed = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2) , OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)




--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field
-- from the date we will see that most answers are Yes or No but we have some N and Y values that we will change to the corresponding values

Select SoldAsVacant, COUNT(SoldAsVacant)
from houses
group by SoldAsVacant


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From houses

UPDATE houses
SET SoldAsVacant = 
	   CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From houses


-- Remove Duplicates
-- we can remove duplicates with different methods this time i will do it with ROW_NUMBER and partition it on the columns that if repeated that means it is for sure a duplicate value
-- the order by in the partition should be on a unique column so it can be either the legalreference or the uniqueid

select *,ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,OwnerName,LegalReference order by LegalReference) 
From houses

select *,ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,OwnerName,LegalReference order by LegalReference) as dub
From houses

-- using a cte to better analyze the dublicate data

WITH dublicates as 
(
select *,ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddressFixed,OwnerName,LegalReference order by LegalReference) dub
From houses
)
select * 
from dublicates 
where dub >1



WITH dublicates as 
(
select *,ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddressFixed,OwnerName,LegalReference order by LegalReference) dub
From houses
)
delete
from dublicates 
where dub >1



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
-- We dont normally delete unused columns in a production environment but this is just a showcase so there is no harm in that 



ALTER TABLE houses
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate



-----------------------------------------------------------------

