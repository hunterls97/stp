with watItemsC as(
  select 'F' as SEC,
       'Watering Unit'||' - '|| ci.YEAR || ' Trees' as "ITEM",
       nvl(count(cd.ID), 0) as "QTY"
       from STP_CONTRACT_DETAIL cd 
       join STP_CONTRACT_ITEM ci on cd.CONTRACT_ITEM_ID = ci.ID
       left join STP_WATERING_ADDITIONAL_ITEM s on s.CONTRACT_ITEM_ID = ci.ID
       where ci.YEAR = :P0_YEAR
       group by ci.YEAR, cd.ID
), -- to avoid unnoticed duplicates, im doing the grouping later

watItems as(
select 'F' as SEC, 
       'Watering Unit'||' - '|| to_char(d.CONTRACTYEAR) || ' Trees' as "ITEM",
       d.CONTRACTYEAR as "YR"
       from STP_DEFICIENCY_V d
       join transd.fsttree@etrans t on d.TREEID = t.TREEID
       where d.CONTRACTYEAR in (:P0_YEAR - 1, :P0_YEAR - 2)
       and t.status = 'Active'
       and d.TREEID in (select TREEID 
                        from transd.fstinspection@etrans i 
                        where extract(year from inspectiondate) = d.CONTRACTYEAR)
       group by d.CONTRACTYEAR, d.TREEID
),  -- to avoid unnoticed duplicates, im doing the grouping later

items as(
  select distinct
       case when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 1 then 'A' --tree plant tree
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 2 then 'B' -- tree plant potted perennial/grass
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 3 then 'C' -- tree plant shrubs
       when s.TYPE_ID = 3 then 'D' -- transplant
       when s.TYPE_ID = 2 then 'E' -- stumping
       --when s.TYPE_ID = 4 then 'F' -- watering item
       end as "SEC",
       
       --item
       s.STOCK_TYPE ||' - '|| s.PLANT_TYPE ||' - '  as "ITEM",--|| t.SPECIES as "ITEM",
       -- using t.species for now, use STP_SPECIES when we have data
       
       --unit
       case SPV.MEASUREMENT
       when 'Each' then 'EA'
       when 'Lump Sum' then 'LS'
       end as "UNIT",
       
       --unit price
       SPV.UNIT_PRICE as "UP",     
       s.YEAR as "YEAR",
       s.CONTRACT_ITEM_ID,
       SCI.ITEM_NUM as "CONTRACT_NUM"
       from STP_CONTRACT_DETAIL_V s
       left join STP_PRICE_V SPV on SPV.STOCK_TYPE_ID = s.STOCK_TYPE_ID and SPV.PLANT_TYPE_ID = s.PLANT_TYPE_ID and SPV.SPECIES_ID = s.SPECIES_ID
       left join STP_CONTRACT_ITEM SCI on SCI.ID = s.CONTRACT_ITEM_ID
       left join STP_WATERING_ADDITIONAL_ITEM SWI on SWI.CONTRACT_ITEM_ID = SCI.ID
       where s.TYPE_ID in (1,2,3) 
       order by 1
),

pCalc as (
  select d.CONTRACTYEAR as "YR",
  nvl((select sum(QTY) 
         from STP_WATERING_ADDITIONAL_ITEM s
         join STP_CONTRACT_ITEM ci on s.CONTRACT_ITEM_ID = ci.ID
         where ci.YEAR = d.CONTRACTYEAR), 0) as "AP"   
         from STP_DEFICIENCY_V d
         group by d.CONTRACTYEAR
)

select i.SEC as "Section",
       --i.INO as "Item No.",
       i.ITEM as "Item",
       nvl(i.UNIT, 'N/A') as "Unit",
       nvl(count(i.ITEM), 0) as "Quantity",
       nvl(i.UP, 0) as "Unit Price",
       nvl(count(i.ITEM) * i.UP, 0) as "Total"
       from items i
       where (i.YEAR = :P0_YEAR) or (i.SEC = 'F' and i.YEAR in (:P0_YEAR, :P0_YEAR - 1, :P0_YEAR - 2))
       and i.SEC is not null
       group by i.SEC, i.ITEM, i.UNIT, i.UP
       union all
       select c.SEC as "Section",
              c.ITEM as "Item",
              'N/A' as "Unit",
              nvl(count(c.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = :P0_YEAR), 0)
                as "Quantity",
              4.78 as "Unit Price",
              nvl(count(c.ITEM) + (select p.AP from pCalc p 
              where p.YR = :P0_YEAR), 0) * 4.78 as "total"
       from watItemsC c
       group by c.SEC, c.ITEM
       union all
       select wi.SEC as "Section",
              wi.ITEM as "Item",
              'N/A' as "Unit",
              nvl(count(wi.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = wi.YR), 0)
              as "Quantity",
              4.78 as "Unit Price",
              nvl(count(wi.ITEM) + (select p.AP from pCalc p 
              where p.YR = wi.YR), 0) * 4.78 as "total"
       from watItems wi
       group by wi.SEC, wi.ITEM, wi.YR
       order by 1, 2
      

