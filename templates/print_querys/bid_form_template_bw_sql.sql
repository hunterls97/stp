select null as "filename",
cursor(
    select STPD.year as "year",
    cursor(
        select nvl(ITEM_CODE, 'no_item-') || nvl(SERIAL_NUM, 'no_serial') as "ITEM_NO",
               nvl(SPV.STOCK_TYPE, 'no_stock-') ||' - '|| nvl(SPV.PLANT_TYPE, 'no_plant-') ||' - '|| nvl(SPV.SPECIES, 'no_species') as "ITEM",
               CASE SPV.MEASUREMENT 
                   when 'Each' then 'EA'
                   when 'Lump Sum' then 'LS'
                   else '--'
               end as "UNIT",
               nvl(SCDV.QUANTITY, 0) as "QTY",
               nvl(SPV.UNIT_PRICE, 0) as "UNIT_PRICE",
               nvl(SCDV.QUANTITY, 0) * nvl(SPV.UNIT_PRICE, 0) as "TOTAL"
               from  STP_CONTRACT_DETAIL_V SCDV
               join STP_PRICE_V SPV on SCDV.PLANT_TYPE_ID = SPV.PLANT_TYPE_ID and SCDV.SPECIES_ID = SPV.SPECIES_ID
               where SPV.STOCK_TYPE is not null 
               and SPV.STOCK_TYPE_ID = 1
    ) as "BID_LOOP_A",
    cursor(
        select SPV.ITEM_CODE || SPV.SERIAL_NUM as "ITEM_NO", 
               SPV.STOCK_TYPE ||' - '|| SPV.PLANT_TYPE ||' - '|| SPV.SPECIES as "ITEM",
               CASE SPV.MEASUREMENT 
                   when 'Each' then 'EA'
                   when 'Lump Sum' then 'LS'
               end as "UNIT",
               SCDV.QUANTITY as "QTY",
               SPV.UNIT_PRICE as "UNIT_PRICE",
               SCDV.QUANTITY * SPV.UNIT_PRICE as "TOTAL"
               from  STP_CONTRACT_DETAIL_V SCDV
               join STP_PRICE_V SPV on SCDV.PLANT_TYPE_ID = SPV.PLANT_TYPE_ID and SCDV.SPECIES_ID = SPV.SPECIES_ID
               where SPV.STOCK_TYPE is not null 
               and SPV.STOCK_TYPE_ID = 2
    ) as "BID_LOOP_C",
    cursor(
        select SPV.ITEM_CODE || SPV.SERIAL_NUM as "ITEM_NO", 
               SPV.TYPE ||'-'|| SPV.PLANT_TYPE as "ITEM",
               CASE SPV.MEASUREMENT 
                   when 'Each' then 'EA'
                   when 'Lump Sum' then 'LS'
               end as "UNIT",
               SCDV.QUANTITY as "QTY",
               SPV.UNIT_PRICE as "UNIT_PRICE",
               SCDV.QUANTITY * SPV.UNIT_PRICE as "TOTAL"
               from  STP_CONTRACT_DETAIL_V SCDV
               join STP_PRICE_V SPV on SCDV.TYPE_ID = SPV.TYPE_ID
               where SPV.TYPE_ID = 3
    ) as "BID_LOOP_D"
    from STP_TREE_PLANTING_DETAIL STPD
    where STPD.year = :P0_YEAR 
    group by STPD.year
) "data"
from dual