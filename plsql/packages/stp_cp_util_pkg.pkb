create or replace PACKAGE BODY                                                                                                                                                                                                             STP_CP_UTIL_PKG AS


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
            p_c014 => rec.MEASUREMENT,
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
    l_measurement           BSMART_DATA.STP_CONTRACT_DETAIL.MEASUREMENT%TYPE := APEX_UTIL.GET_SESSION_STATE('P5_MEASUREMENT');
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
            p_c014 => l_measurement,
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
            p_c014 => l_measurement,
            p_n001 => l_quantity,
            p_n004 => 1,
            p_n005 => l_id);

    END IF;

END;

    PROCEDURE process_detail_rows(p_contract_item_id IN BSMART_DATA.STP_CONTRACT_DETAIL.CONTRACT_ITEM_ID%TYPE)
    AS
    BEGIN
        for rec in(
      select c008, c009, c010, c011, c012, c013, c014, c007, n001, n004, n005
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
                                            ,MEASUREMENT
                                            ,DESCRIPTION
                                            ,QUANTITY)
                                    values (P_CONTRACT_ITEM_ID,
                                            rec.c008,
                                            rec.c009,
                                            rec.c010,
                                            rec.c011,
                                            rec.c012,
                                            rec.c013,
                                            rec.c014,
                                            rec.c007,
                                            rec.n001);
            COMMIT;
            
            -- Updating price table.
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
                                        ,MEASUREMENT      = rec.c014
                                        ,QUANTITY           = rec.n001
                                        WHERE ID=rec.n005;

        WHEN rec.n004=0 AND rec.n005 IS NOT NULL THEN -- Deleted record

            BEGIN
            DELETE FROM STP_CONTRACT_DETAIL WHERE ID=rec.n005;
            COMMIT;
            
            stp_pricing_util_pkg.manage_pricing_record(APEX_UTIL.GET_SESSION_STATE('P0_YEAR'),
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
    
END STP_CP_UTIL_PKG;