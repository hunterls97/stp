with watItemsC as(
  select 'F - Watering' as SEC,
       'Watering Unit'||' - '|| ci.YEAR || ' Trees' as "ITEM",
       nvl(count(cd.ID), 0) as "QTY"
       from STP_CONTRACT_DETAIL cd 
       join STP_CONTRACT_ITEM ci on cd.CONTRACT_ITEM_ID = ci.ID
       left join STP_WATERING_ADDITIONAL_ITEM s on s.CONTRACT_ITEM_ID = ci.ID
       where ci.YEAR = :P0_YEAR
       group by ci.YEAR, cd.ID
), -- to avoid unnoticed duplicates, im doing the grouping later

watItems as(
select 'F - Watering' as SEC, 
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
       case when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 1 then 'A - Tree Planting - Ball and Burlap Trees' --tree plant tree
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 2 then 'B - Tree Planting - Potted Perennials and Grass' -- tree plant potted perennial/grass
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 3 then 'C - Tree Planting - Potted Shrubs' -- tree plant shrubs
       when s.TYPE_ID = 3 then 'D - Transplanting' -- transplant
       when s.TYPE_ID = 2 then 'E - Stumping' -- stumping
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
       SPV.LAST_YEAR_PRICE as "LYP",
       SPV.PRICE_EST as "PE",
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
       0 as "Sub",
       --i.INO as "Item No.",
       i.ITEM as "Item",
       nvl(i.UNIT, 'N/A') as "Unit",
       nvl(count(i.ITEM), 0) as "Quantity",
       nvl(i.LYP, 0) as "Last Year Price",
       nvl(i.PE, 0) as "Price Estimate",
       nvl(i.UP, 0) as "Unit Price",
       nvl(count(i.ITEM) * i.PE, 0) as "Estimated Total",
       nvl(count(i.ITEM) * i.UP, 0) as "Total"
       from items i
       where i.YEAR = :P0_YEAR
       and i.SEC is not null
       group by i.SEC, i.ITEM, i.UNIT, i.UP, i.LYP, i.PE
       union all
       select i.SEC as "Section",
       1 as "Sub",
       'Subtotal: ' as "Item",
       null as "Unit",
       nvl((select sum(QT) 
       from (select nvl(count(ii.ITEM), 0) as "QT" 
            from items ii 
            where ii.SEC = i.SEC 
            and ii.YEAR = :P0_YEAR 
            group by ii.ITEM)), 0) as "Quantity",
       null,
       null,
       null as "Unit Price",
       nvl((select sum(TOT) 
       from (select nvl(count(ii.ITEM) * ii.PE, 0) as "TOT"
            from items ii
            where ii.SEC = i.SEC 
            and ii.YEAR = :P0_YEAR 
            group by ii.ITEM, ii.PE)), 0) as "Estimated Total",
       nvl((select sum(TOT) 
       from (select nvl(count(ii.ITEM) * ii.UP, 0) as "TOT"
            from items ii
            where ii.SEC = i.SEC 
            and ii.YEAR = :P0_YEAR 
            group by ii.ITEM, ii.UP)), 0) as "Total"
       from items i
       group by i.SEC
       union all
       select c.SEC as "Section",
              0 as "Sub",
              c.ITEM as "Item",
              'N/A' as "Unit",
              nvl(count(c.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = :P0_YEAR), 0)
                as "Quantity",
              null,
              null,
              4.78 as "Unit Price",
              null,
              nvl(count(c.ITEM) + (select p.AP from pCalc p 
              where p.YR = :P0_YEAR), 0) * 4.78 as "total"
       from watItemsC c
       group by c.SEC, c.ITEM
       union all
       select wi.SEC as "Section",
              0 as "Sub",
              wi.ITEM as "Item",
              'N/A' as "Unit",
              nvl(count(wi.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = wi.YR), 0)
              as "Quantity",
              null,
              null,
              4.78 as "Unit Price",
              null,
              nvl(count(wi.ITEM) + (select p.AP from pCalc p 
              where p.YR = wi.YR), 0) * 4.78 as "total"
       from watItems wi
       group by wi.SEC, wi.ITEM, wi.YR
       union all
       select 
       'F - Watering' as "SEC",
       1 as "Sub",
       'Subtotal: ' as "Item",
       null as "Unit",
       nvl((select sum(QT) from (select (nvl(count(wi.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = wi.YR), 0)) as "QT" from watItems wi
              group by wi.ITEM, wi.YR
              union all
              select (nvl(count(c.ITEM), 0) + nvl((select p.AP 
              from pCalc p where p.YR = :P0_YEAR), 0)) as "QT" from watItemsC c
              group by c.ITEM)), 0) as "Quantity",
       null,
       null,
       null,
       null,
       nvl((select sum(TOT) from( select (nvl(count(c.ITEM) + (select p.AP from pCalc p 
              where p.YR = :P0_YEAR), 0) * 4.78) as "TOT" from watItemsC c
              group by c.ITEM
              union all
              select (nvl(count(wi.ITEM) + (select p.AP from pCalc p 
              where p.YR = wi.YR), 0) * 4.78) as "TOT" from watItems wi
              group by wi.ITEM, wi.YR
       )), 0) as "Total"  
       from dual


