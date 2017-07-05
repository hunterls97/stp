create or replace PACKAGE BODY                                                                                                                                     STP_CP_UTIL_PKG AS


PROCEDURE load_detail_row(P_CONTRACT_ITEM_ID IN BSMART_DATA.STP_CONTRACT_DETAIL.CONTRACT_ITEM_ID%TYPE)
AS
    BEGIN
 

    /* Truncate Collection if exsits. */
    if APEX_COLLECTION.COLLECTION_EXISTS (DETAIL_COLLECTION_NAME) then
        APEX_COLLECTION.DELETE_COLLECTION (DETAIL_COLLECTION_NAME);
    end if;

    APEX_COLLECTION.CREATE_COLLECTION(DETAIL_COLLECTION_NAME);


    /* Load detail rows into collection. */
    for rec in (SELECT *
                from STP_CONTRACT_DETAIL_V
                WHERE CONTRACT_ITEM_ID = P_CONTRACT_ITEM_ID)
    loop
        
        APEX_COLLECTION.ADD_MEMBER (
            p_collection_name => DETAIL_COLLECTION_NAME,
            p_c001 => rec.TYPE,
            p_c002 => rec.STOCK_TYPE,
            p_c003 => rec.PLANT_TYPE,
            p_c004 => rec.SPECIES,
            p_c005 => rec.STUMPING_SIZE,
            p_c006 => rec.TRANSP_DIS,
            p_c007 => rec.DESCRIPTION,
            p_c008 => rec.TYPE_ID,
            p_c009 => rec.STOCK_TYPE_ID,
            p_c010 => rec.PLANT_TYPE_ID,
            p_c011 => rec.SPECIES_ID,
            p_c012 => rec.STUMPING_SIZE_ID,
            p_c013 => rec.TRANSP_DIS_ID,
            p_n001 => rec.QUANTITY,
            p_n004 => 1,
            p_n005 => rec.ID);
    end loop;
    END;


PROCEDURE create_or_save_detail_row
AS
    l_seq_id                NUMBER := APEX_UTIL.GET_SESSION_STATE('P5_SEQ');
    l_type_id               BSMART_DATA.STP_CONTRACT_DETAIL.TYPE_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_TYPE_ID'); 
    l_stock_type_id         BSMART_DATA.STP_CONTRACT_DETAIL.STOCK_TYPE_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_STOCK_TYPE');
    l_plant_type_id         BSMART_DATA.STP_CONTRACT_DETAIL.PLANT_TYPE_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_PLANT_TYPE');
    l_species_id            BSMART_DATA.STP_CONTRACT_DETAIL.SPECIES_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_SPECIES');
    l_stumping_size_id      BSMART_DATA.STP_CONTRACT_DETAIL.STUMPING_SIZE_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_STUMPING_SIZE');
    l_transp_dis_id         BSMART_DATA.STP_CONTRACT_DETAIL.TRANSP_DIS_ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_TRANSP_DIS');
    l_description           BSMART_DATA.STP_CONTRACT_DETAIL.DESCRIPTION%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_DESCRIPTION');
    l_quantity              BSMART_DATA.STP_CONTRACT_DETAIL.QUANTITY%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_QUANTITY');
    l_id                    BSMART_DATA.STP_CONTRACT_DETAIL.ID%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_ID');
    l_type                  varchar2(128);
    l_stock_type            varchar2(128);
    l_plant_type            varchar2(128);
    l_species               varchar2(128);
    l_stumping_size         varchar2(128);
    l_transp_dis            varchar2(128);
BEGIN

    l_type              := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_ACTIVITY_TYPE, l_type_id);
    l_stock_type        := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_STOCK_TYPE,    l_stock_type_id );
    l_plant_type        := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_PLANT_TYPE,    l_plant_type_id);
    l_species           := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_SPECIES,       l_species_id);
    l_stumping_size     := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_STUMP_SIZE,    l_stumping_size_id);
    l_transp_dis        := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_TRANSP_DIS,    l_transp_dis_id);


    IF l_seq_id is NULL then
        APEX_COLLECTION.ADD_MEMBER (
            p_collection_name => DETAIL_COLLECTION_NAME,
            p_c001 => l_type,
            p_c002 => l_stock_type,
            p_c003 => l_plant_type,
            p_c004 => l_species,
            p_c005 => l_stumping_size,
            p_c006 => l_transp_dis,
            p_c007 => l_description,
            p_c008 => l_type_id,
            p_c009 => l_stock_type_id,
            p_c010 => l_plant_type_id,
            p_c011 => l_species_id,
            p_c012 => l_stumping_size_id,
            p_c013 => l_transp_dis_id,
            p_n001 => l_quantity,
            p_n004 => 1,
            p_n005 => l_id);
    ELSE
    
        APEX_COLLECTION.UPDATE_MEMBER (
            p_collection_name => DETAIL_COLLECTION_NAME,
            p_seq => l_seq_id,
            p_c001 => l_type,
            p_c002 => l_stock_type,
            p_c003 => l_plant_type,
            p_c004 => l_species,
            p_c005 => l_stumping_size,
            p_c006 => l_transp_dis,
            p_c007 => l_description,
            p_c008 => l_type_id,
            p_c009 => l_stock_type_id,
            p_c010 => l_plant_type_id,
            p_c011 => l_species_id,
            p_c012 => l_stumping_size_id,
            p_c013 => l_transp_dis_id,
            p_n001 => l_quantity,
            p_n004 => 1,
            p_n005 => l_id);

    END IF;

END;

    PROCEDURE process_detail_rows(p_contract_item_id IN BSMART_DATA.STP_CONTRACT_DETAIL.CONTRACT_ITEM_ID%TYPE)
    AS
    BEGIN
        for rec in(
      select c008, c009, c010, c011, c012, c013, c007, n001, n004, n005
      from apex_collections
      where collection_name = DETAIL_COLLECTION_NAME
    )
    loop
        CASE 
        WHEN rec.n004=1 AND rec.n005 IS NULL THEN  -- New record
            BEGIN
            INSERT INTO STP_CONTRACT_DETAIL (CONTRACT_ITEM_ID
                                            ,TYPE_ID
                                            ,STOCK_TYPE_ID
                                            ,PLANT_TYPE_ID
                                            ,SPECIES_ID
                                            ,STUMPING_SIZE_ID
                                            ,TRANSP_DIS_ID
                                            ,DESCRIPTION
                                            ,QUANTITY)
                                    values (P_CONTRACT_ITEM_ID,
                                            rec.c008,
                                            rec.c009,
                                            rec.c010,
                                            rec.c011,
                                            rec.c012,
                                            rec.c013,
                                            rec.c007,
                                            rec.n001);
            COMMIT;
            
            BSMART_DATA.STP_PRICING_UTIL_PKG.manage_pricing_record(APEX_UTIL.GET_SESSION_STATE('P0_YEAR'),
                                                           rec.c008,
                                                           rec.c009,
                                                           rec.c010,
                                                           rec.c011,
                                                           rec.c012,
                                                           rec.c013,
                                                           'INSERTING');
            END;
                                        
        WHEN rec.n004=1 AND rec.n005 IS NOT NULL THEN  -- Exsiting record
        UPDATE STP_CONTRACT_DETAIL SET   STOCK_TYPE_ID      = rec.c009
                                        ,PLANT_TYPE_ID      = rec.c010
                                        ,SPECIES_ID         = rec.c011
                                        ,STUMPING_SIZE_ID   = rec.c012
                                        ,TRANSP_DIS_ID      = rec.c013
                                        ,DESCRIPTION     = rec.c007
                                        ,QUANTITY           = rec.n001
                                        WHERE ID=rec.n005;

        WHEN rec.n004=0 AND rec.n005 IS NOT NULL THEN -- Deleted record

            BEGIN
            DELETE FROM STP_CONTRACT_DETAIL WHERE ID=rec.n005;
            COMMIT;
            
            BSMART_DATA.STP_PRICING_UTIL_PKG.manage_pricing_record(APEX_UTIL.GET_SESSION_STATE('P0_YEAR'),
                                               rec.c008,
                                               rec.c009,
                                               rec.c010,
                                               rec.c011,
                                               rec.c012,
                                               rec.c013,
                                               'DELETING');
            END;
        ELSE
        NULL;
        END CASE;
    end loop;
    END;
    
    FUNCTION AOP_costing_summary RETURN varchar2
    as
      l_return clob;
    begin
      l_return := q'[
        with watItemsC as(
  select 'F - Watering' as SEC,
        cd.TYPE as "TYPE",
        cd.PROGRAM as "PROGRAM",
       'Watering Unit'||' - '|| ci.YEAR || ' Trees' as "ITEM",
       nvl(cd.QUANTITY, 0) * 14 as "QTY"
       from STP_CONTRACT_DETAIL_V cd 
       join STP_CONTRACT_ITEM ci on cd.CONTRACT_ITEM_ID = ci.ID
       left join STP_WATERING_ADDITIONAL_ITEM s on s.CONTRACT_ITEM_ID = ci.ID
       where ci.YEAR = :P0_YEAR 
       and (cd.STOCK_TYPE_ID is not null and cd.PLANT_TYPE_ID is not null)
       and cd.TYPE_ID in (1,2,3)
       group by cd.ID, ci.YEAR, cd.QUANTITY, cd.TYPE, cd.PROGRAM
), -- to avoid unnoticed duplicates, im doing the grouping later

watItems as(
select 'F - Watering' as SEC, 
       'Watering Unit'||' - '|| to_char(STLV.CONTRACTYEAR) || ' Trees' as "ITEM",
       STLV.CONTRACTYEAR as "YR"
       from STP_TREE_LOCATION_V STLV
       where STLV.CONTRACTYEAR in (:P0_YEAR - 1, :P0_YEAR - 2)
       and STLV.status = 'Active'
       and STLV.TREEID in (select TREEID 
                        from STP_TREE_LOCATION_V i
                        where extract(year from i.inspectiondate) = STLV.CONTRACTYEAR)
       group by STLV.CONTRACTYEAR, STLV.TREEID
),  -- to avoid unnoticed duplicates, im doing the grouping later

items as(
  select 
       case when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 1 then 'A - Tree Planting - Ball and Burlap Trees' --tree plant tree
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 2 then 'B - Tree Planting - Potted Perennials and Grass' -- tree plant potted perennial/grass
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 3 then 'C - Tree Planting - Potted Shrubs' -- tree plant shrubs
       when s.TYPE_ID = 3 then 'D - Transplanting' -- transplant
       when s.TYPE_ID = 2 then 'E - Stumping' -- stumping
       --when s.TYPE_ID = 4 then 'F' -- watering item
       end as "SEC",
       s.QUANTITY as "QUANTITY",
       s.PROGRAM as "PROGRAM",
       
       --item
       s.STOCK_TYPE ||' - '|| s.PLANT_TYPE ||' - ' || s.SPECIES  as "ITEM",--|| t.SPECIES as "ITEM",
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
  nvl((select sum(nvl(QTY, 0)) * 14 
         from STP_WATERING_ADDITIONAL_ITEM s
         join STP_CONTRACT_ITEM ci on s.CONTRACT_ITEM_ID = ci.ID
         where ci.YEAR = d.CONTRACTYEAR), 0) as "AP"   
         from STP_DEFICIENCY_V d
         group by d.CONTRACTYEAR
)

select null as "filename",
cursor(
  select 
  cursor(
    select conItem.PROGRAM as "PRO",
    cursor(
      select 
      cursor(
        select i.ITEM as "ITEM",
         sum(nvl(i.QUANTITY, 0)) as "QT",
         nvl(i.LYP, 0) as "LYP",
         nvl(i.PE, 0) as "PE",
         nvl(i.UP, 0) as "UP",
         nvl(sum(nvl(i.QUANTITY, 0)) * i.PE, 0) as "ETOT",
         nvl(sum(nvl(i.QUANTITY, 0)) * i.UP, 0) as "TOT"
         from items i
         where i.YEAR = :P0_YEAR
         and i.PROGRAM = conItem.PROGRAM
         and i.SEC is not null
         group by i.SEC, i.ITEM, i.UNIT, i.UP, i.LYP, i.PE
      ) "PITEMS",
      cursor(
         select distinct
         i.PROGRAM,
         nvl((select sum(QT) 
         from (select nvl(sum(ii.QUANTITY), 0) as "QT" ,
              ii.PROGRAM as "PROGRAM"
              from items ii  
              where ii.YEAR = :P0_YEAR 
              group by ii.ITEM, ii.PROGRAM)
              where PROGRAM = i.PROGRAM), 0) as "PQT",
         nvl((select sum(TOT) 
         from (select nvl(sum(ii.QUANTITY) * ii.PE, 0) as "TOT",
              ii.PROGRAM as "PROGRAM"
              from items ii
              where ii.YEAR = :P0_YEAR 
              group by ii.ITEM, ii.PE, ii.PROGRAM)
              where PROGRAM = i.PROGRAM), 0) as "PETOT",
         nvl((select sum(TOT)
         from (select nvl(sum(ii.QUANTITY) * ii.UP, 0) as "TOT",
              ii.PROGRAM as "PROGRAM"
              from items ii
              where ii.YEAR = :P0_YEAR 
              group by ii.ITEM, ii.UP, ii.PROGRAM)
              where PROGRAM = i.PROGRAM), 0) as "PTOT"
         from items i
         where i.PROGRAM = conITEM.PROGRAM
      ) "PTOTS",
      cursor(
        select c.ITEM as "ITEM",
                (nvl(sum(c.QTY), 0) + nvl((select p.AP 
                from pCalc p where p.YR = :P0_YEAR), 0))
                  as "QT",
                4.78 as "UP",
                (nvl(sum(c.QTY) + (select p.AP from pCalc p 
                where p.YR = :P0_YEAR), 0)) * 4.78 as "TOT"
         from watItemsC c
         where c.PROGRAM = conItem.PROGRAM
         group by c.SEC, c.ITEM
      ) "WITEMSCUR",
      cursor(
        select wi.ITEM as "ITEM",
                (nvl(count(wi.ITEM), 0)) * 14
                as "QT",
                4.78 as "UP",
                nvl(count(wi.ITEM), 0) * 4.78 * 14 as "TOT"
         from watItems wi
         group by wi.SEC, wi.ITEM, wi.YR
      ) "WITEMS",
      cursor(
         select 
         nvl((select sum(QT) from (select (nvl(count(wi.ITEM), 0)) * 14 as "QT" from watItems wi
                group by wi.ITEM, wi.YR
                union all
                select (nvl(sum(c.QTY), 0) + nvl((select p.AP 
                from pCalc p where p.YR = :P0_YEAR), 0)) as "QT" from watItemsC c
                where c.PROGRAM = conItem.PROGRAM
                group by c.ITEM)), 0) as "WQT",
         nvl((select sum(TOT) from( select (nvl(sum(c.QTY) + (select p.AP from pCalc p 
                where p.YR = :P0_YEAR), 0)) as "TOT" from watItemsC c
                where c.PROGRAM = conItem.PROGRAM
                group by c.ITEM
                union all
                select (nvl(count(wi.ITEM), 0)) * 14
                as "TOT" from watItems wi
                group by wi.ITEM, wi.YR
         )), 0) * 4.78 as "WTOT"  
         from dual
      ) "WTOTS"
      from dual
    ) "PROGRAMS"
    from STP_CONTRACT_ITEM conItem
    where exists(
      select i.ITEM as "ITEM",
         sum(nvl(i.QUANTITY, 0)) as "QT",
         nvl(i.LYP, 0) as "LYP",
         nvl(i.PE, 0) as "PE",
         nvl(i.UP, 0) as "UP",
         nvl(sum(nvl(i.QUANTITY, 0)) * i.PE, 0) as "ETOT",
         nvl(sum(nvl(i.QUANTITY, 0)) * i.UP, 0) as "TOT"
         from items i
         where i.YEAR = :P0_YEAR
         and i.PROGRAM = conItem.PROGRAM
         group by i.SEC, i.ITEM, i.UNIT, i.UP, i.LYP, i.PE
    )
    group by conItem.PROGRAM
  ) "OUTER"
  from dual
) "data"
from dual
      ]';
      
      return l_return;
    end;
    
    FUNCTION AOP_bid_form_summary RETURN varchar2
    as
      l_return clob;
    begin
      l_return := q'[
        with watItemsC as(
  select 'F - Watering' as SEC,
        cd.TYPE as "TYPE",
        cd.PROGRAM as "PROGRAM",
       'Watering Unit'||' - '|| ci.YEAR || ' Trees' as "ITEM",
       nvl(cd.QUANTITY, 0) * 14 as "QTY"
       from STP_CONTRACT_DETAIL_V cd 
       join STP_CONTRACT_ITEM ci on cd.CONTRACT_ITEM_ID = ci.ID
       left join STP_WATERING_ADDITIONAL_ITEM s on s.CONTRACT_ITEM_ID = ci.ID
       where ci.YEAR = :P0_YEAR 
       and (cd.STOCK_TYPE_ID is not null and cd.PLANT_TYPE_ID is not null)
       and cd.TYPE_ID in (1,2,3)
       group by cd.ID, ci.YEAR, cd.QUANTITY, cd.TYPE, cd.PROGRAM
), -- to avoid unnoticed duplicates, im doing the grouping later

watItems as(
select 'F - Watering' as SEC, 
       'Watering Unit'||' - '|| to_char(STLV.CONTRACTYEAR) || ' Trees' as "ITEM",
       STLV.CONTRACTYEAR as "YR"
       from STP_TREE_LOCATION_V STLV
       where STLV.CONTRACTYEAR in (:P0_YEAR - 1, :P0_YEAR - 2)
       and STLV.status = 'Active'
       and STLV.TREEID in (select TREEID 
                        from STP_TREE_LOCATION_V i
                        where extract(year from i.inspectiondate) = STLV.CONTRACTYEAR)
       group by STLV.CONTRACTYEAR, STLV.TREEID
),  -- to avoid unnoticed duplicates, im doing the grouping later

items as(
  select 
       case when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 1 then 'A - Tree Planting - Ball and Burlap Trees' --tree plant tree
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 2 then 'B - Tree Planting - Potted Perennials and Grass' -- tree plant potted perennial/grass
       when s.TYPE_ID = 1 and s.STOCK_TYPE_ID = 3 then 'C - Tree Planting - Potted Shrubs' -- tree plant shrubs
       when s.TYPE_ID = 3 then 'D - Transplanting' -- transplant
       when s.TYPE_ID = 2 then 'E - Stumping' -- stumping
       --when s.TYPE_ID = 4 then 'F' -- watering item
       end as "SEC",
       s.QUANTITY as "QUANTITY",
       s.PROGRAM as "PROGRAM",
       
       --item
       s.STOCK_TYPE ||' - '|| s.PLANT_TYPE ||' - ' || s.SPECIES  as "ITEM",--|| t.SPECIES as "ITEM",
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
  nvl((select sum(nvl(QTY, 0)) * 14 
         from STP_WATERING_ADDITIONAL_ITEM s
         join STP_CONTRACT_ITEM ci on s.CONTRACT_ITEM_ID = ci.ID
         where ci.YEAR = d.CONTRACTYEAR), 0) as "AP"   
         from STP_DEFICIENCY_V d
         group by d.CONTRACTYEAR
)

select null as "filename",
cursor(
  select
  cursor(
    select ii.SEC,
      cursor(
        select 
        cursor(
           select i.SEC as "SECTION",
           --i.INO as "Item No.",
           'TODO' as "INO",
           i.ITEM as "ITEM",
           nvl(i.UNIT, 'N/A') as "UNIT",
           sum(nvl(i.QUANTITY, 0)) as "QT",
           nvl(i.UP, 0) as "UP",
           nvl(sum(nvl(i.QUANTITY, 0)) * i.UP, 0) as "TOT"
           from items i
           where i.YEAR = :P0_YEAR
           and i.SEC is not null
           and i.SEC = ii.SEC
           group by i.SEC, i.ITEM, i.UNIT, i.UP
           union all
           select c.SEC as "SECTION",
                  'TODO' as "INO",
                   c.ITEM as "ITEM",
                  'N/A' as "UNIT",
                  (nvl(sum(c.QTY), 0) + nvl((select p.AP 
                  from pCalc p where p.YR = :P0_YEAR), 0))
                    as "QT",
                  4.78 as "UP",
                  (nvl(sum(c.QTY) + (select p.AP from pCalc p 
                  where p.YR = :P0_YEAR), 0)) * 4.78 as "TOT"
           from watItemsC c
           where c.SEC = ii.SEC
           group by c.SEC, c.ITEM
           union all
           select wi.SEC as "SECTION",
                  'TODO' as "INO",
                  wi.ITEM as "ITEM",
                  'N/A' as "UNIT",
                  (nvl(count(wi.ITEM), 0)) * 14
                  as "QT",
                  4.78 as "UP",
                  nvl(count(wi.ITEM), 0) * 4.78 * 14 as "TOT"
           from watItems wi
           where wi.SEC = ii.SEC
           group by wi.SEC, wi.ITEM, wi.YR
          ) "ITEMS"
          from dual
      ) "SECTIONS"
    from items ii
    where exists(
      select 
         i.ITEM as "Item"
         from items i
         where i.YEAR = :P0_YEAR
         and i.SEC is not null
         and i.SEC = ii.SEC
         group by i.SEC, i.ITEM, i.UNIT, i.UP
         union all
         select  c.ITEM as "Item"
         from watItemsC c
         where c.SEC = ii.SEC
         group by c.SEC, c.ITEM
         union all
         select wi.ITEM as "Item"
         from watItems wi
         where wi.SEC = ii.SEC
         group by wi.SEC, wi.ITEM, wi.YR
    )
    group by ii.SEC  
    order by ii.SEC
  ) "OUTER"
  from dual
) "data"
from dual
      ]';
      
      return l_return;
    end;



END STP_CP_UTIL_PKG;