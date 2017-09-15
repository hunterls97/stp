create or replace PACKAGE BODY                                                                                     STP_TPD_UTIL_PKG AS

    /************************************************************************************************
    /*
    /* @procedure: load_detail_row
    /*
    /* @description: load the detail rows into collection named G_DETAIL_COLLECTION_NAME
    /*             
    /* @type P_TREE_PLANTING_DETAIL_ID In Number - tree planting detail id
    /************************************************************************************************/ 
    PROCEDURE load_detail_row(P_TREE_PLANTING_DETAIL_ID IN  STP_TREE_PLANTING_DETAIL_ROW.TREE_PLANTING_DETAIL_ID%TYPE)
    AS
        BEGIN 
      
        /* Truncate Collection if exsits. */
        if APEX_COLLECTION.COLLECTION_EXISTS (G_DETAIL_COLLECTION_NAME) then
            APEX_COLLECTION.DELETE_COLLECTION (G_DETAIL_COLLECTION_NAME);
        end if;

        APEX_COLLECTION.CREATE_COLLECTION(G_DETAIL_COLLECTION_NAME);

     
        /* Load detail rows into collection. */
        for rec in (SELECT *
                    from STP_TREE_PLANTING_DETAIL_ROW_V
                    WHERE TREE_PLANTING_DETAIL_ID = P_TREE_PLANTING_DETAIL_ID)
        loop
            
            APEX_COLLECTION.ADD_MEMBER (
                p_collection_name => G_DETAIL_COLLECTION_NAME,
                p_c001            => rec.TYPE,
                p_c002            => rec.STOCK_TYPE,
                p_c003            => rec.PLANT_TYPE, 
                p_c004            => rec.SPECIES,
                p_c005            => rec.STUMP_SIZE, 
                p_c006            => rec.TRANSP_DIS,
                p_c007            => rec.comments,
                p_c008            => rec.TYPE_ID,
                p_c009            => rec.STOCK_TYPE_ID,
                p_c010            => rec.PLANT_TYPE_ID, 
                p_c011            => rec.SPECIES_ID,
                p_c012            => rec.STUMP_SIZE_ID,
                p_c013            => rec.TRANSPLANTING_DISTANCE_ID,
                p_c014            => rec.RIN,
                p_c016            => rec.ROADSIDE,
                p_c017            => rec.BETWEEN_ROAD_1,
                p_c018            => rec.BETWEEN_ROAD_2,
                p_c019            => rec.ADDRESS,
                p_c020            => rec.MARK_TYPE_ID,
                p_c021            => rec.MARK_TYPE,
                p_c022            => rec.MARKING_LOCATION_ID,
                p_c023            => rec.MARKING_LOCATION,
                p_c024            => rec.OFFSET_FROM_MARK,
                p_c025            => rec.SPACING_ON_CENTRE,
                p_c026            => rec.HYDRO,
                p_n001            => rec.QUANTITY,
                p_n003            => rec.ORDER_NO,
                p_n004            => 1,
                p_n005            => rec.ID);
                
        end loop;
        END;

    /************************************************************************************************
    /*
    /* @procedure: create_or_save_detail_row
    /*
    /* @description: Manipulate tree planting detail rows.
    /*             
    /* @type P_TREE_PLANTING_DETAIL_ID In Number - tree planting detail id
    /*
    /* @note: this precedure only manipulate data in the collection but not the actual table. And this
    /*        this procedure would be affected if the page items are changed.
    /************************************************************************************************/ 
    PROCEDURE create_or_save_detail_row(P_TREE_PLANTING_DETAIL_ID IN  BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.TREE_PLANTING_DETAIL_ID%TYPE)
    AS
        l_seq_id                NUMBER                                                                 := APEX_UTIL.GET_SESSION_STATE('P43_SEQ');
        l_type_id               BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.ACTIVITY_TYPE_ID%TYPE         := APEX_UTIL.GET_SESSION_STATE('P43_TYPE_ID'); 
        l_stock_type_id         BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.STOCK_TYPE_ID%TYPE            := APEX_UTIL.GET_SESSION_STATE('P43_STOCK_TYPE');
        l_plant_type_id         BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.PLANT_TYPE_ID%TYPE            := APEX_UTIL.GET_SESSION_STATE('P43_PLANT_TYPE');
        l_species_id            BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.SPECIES_ID%TYPE               := APEX_UTIL.GET_SESSION_STATE('P43_SPECIES');
        l_stumping_size_id      BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.STUMP_SIZE_ID%TYPE            := APEX_UTIL.GET_SESSION_STATE('P43_STUMPING_SIZE');
        l_transp_dis_id         BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.TRANSPLANTING_DISTANCE_ID%TYPE:= APEX_UTIL.GET_SESSION_STATE('P43_TRANSP_DIS');
        l_quantity              BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.QTY%TYPE                      := APEX_UTIL.GET_SESSION_STATE('P43_QUANTITY');
        l_id                    BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.ID%TYPE                       := APEX_UTIL.GET_SESSION_STATE('P43_ID');
        l_mark_type_id          BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.MARK_TYPE_ID%TYPE             := APEX_UTIL.GET_SESSION_STATE('P43_MARK_TYPE');
        l_marking_location_id   BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.MARKING_LOCATION_ID%TYPE      := APEX_UTIL.GET_SESSION_STATE('P43_MARKING_LOCATION');
        l_offset_from_mark      BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.OFFSET_FROM_MARK%TYPE         := APEX_UTIL.GET_SESSION_STATE('P43_OFFSET');
        l_spacing_on_centre     BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.SPACING_ON_CENTRE%TYPE        := APEX_UTIL.GET_SESSION_STATE('P43_SPACE');
        l_hydro                 BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.HYDRO%TYPE                    := APEX_UTIL.GET_SESSION_STATE('P43_HYDRO');
        l_rin                   BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.RIN%TYPE                      := APEX_UTIL.GET_SESSION_STATE('P43_RIN');
        l_roadside              BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.ROADSIDE%TYPE                 := APEX_UTIL.GET_SESSION_STATE('P43_ROADSIDE');
        l_between_road_1        BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.BETWEEN_ROAD_1%TYPE           := APEX_UTIL.GET_SESSION_STATE('P43_BETWEEN_ROAD_1');
        l_between_road_2        BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.BETWEEN_ROAD_2%TYPE           := APEX_UTIL.GET_SESSION_STATE('P43_BETWEEN_ROAD_2');
        l_address               BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.ADDRESS%TYPE                  := APEX_UTIL.GET_SESSION_STATE('P43_ADDRESS');
        l_comments              BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.COMMENTS%TYPE                 := APEX_UTIL.GET_SESSION_STATE('P43_COMMENTS');


        l_type                  varchar2(128);
        l_stock_type            varchar2(128);
        l_plant_type            varchar2(128);
        l_species               varchar2(128);
        l_stumping_size         varchar2(128);
        l_transp_dis            varchar2(128);
        l_mark_type             varchar2(128);
        l_marking_location      varchar2(128);
        l_order_no              NUMBER;
    BEGIN

        /* Load domains. */
        l_type             := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_ACTIVITY_TYPE,    l_type_id);
        l_stock_type       := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_STOCK_TYPE,       l_stock_type_id );
        l_plant_type       := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_PLANT_TYPE,       l_plant_type_id);
        l_species          := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_SPECIES,          l_species_id);
        l_stumping_size    := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_STUMP_SIZE,       l_stumping_size_id);
        l_transp_dis       := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_TRANSP_DIS,       l_transp_dis_id);
        l_mark_type        := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_MARK_TYPE,        l_mark_type);
        l_marking_location := STP_UTIL_PKG.LOAD_PARAMETER(STP_CONSTANT_PKG.GC_T_MARKING_LOCATION, l_marking_location);
        
        IF l_seq_id is NULL then

            -- Create new.
            select nvl(max(ORDER_NO), 0) + 1 into l_order_no FROM STP_TREE_PLANTING_DETAIL_ROW where TREE_PLANTING_DETAIL_ID = P_TREE_PLANTING_DETAIL_ID;
            APEX_COLLECTION.ADD_MEMBER (
                p_collection_name => G_DETAIL_COLLECTION_NAME,
                p_c001 => l_type,
                p_c002 => l_stock_type,
                p_c003 => l_plant_type,
                p_c004 => l_species,
                p_c005 => l_stumping_size,
                p_c006 => l_transp_dis,
                p_c007 => l_comments,
                p_c008 => l_type_id,
                p_c009 => l_stock_type_id,
                p_c010 => l_plant_type_id,
                p_c011 => l_species_id,
                p_c012 => l_stumping_size_id,
                p_c013 => l_transp_dis_id,
                p_c014 => l_rin,
                p_c016 => l_roadside,
                p_c017 => l_between_road_1,
                p_c018 => l_between_road_2,
                p_c019 => l_address,
                p_c020 => l_mark_type_id,
                p_c021 => l_mark_type,
                p_c022 => l_marking_location_id,
                p_c023 => l_marking_location,
                p_c024 => l_offset_from_mark,
                p_c025 => l_spacing_on_centre,
                p_c026 => l_hydro,
                p_n001 => l_quantity,
                p_n003 => l_order_no,
                p_n004 => 1);
        ELSE
            
            -- Update existings.
            APEX_COLLECTION.UPDATE_MEMBER (
                p_collection_name => G_DETAIL_COLLECTION_NAME,
                p_seq => l_seq_id,
                p_c001 => l_type,
                p_c002 => l_stock_type,
                p_c003 => l_plant_type,
                p_c004 => l_species,
                p_c005 => l_stumping_size,
                p_c006 => l_transp_dis,
                p_c007 => l_comments,
                p_c008 => l_type_id,
                p_c009 => l_stock_type_id,
                p_c010 => l_plant_type_id,
                p_c011 => l_species_id,
                p_c012 => l_stumping_size_id,
                p_c013 => l_transp_dis_id,
                p_c014 => l_rin,
                p_c016 => l_roadside,
                p_c017 => l_between_road_1,
                p_c018 => l_between_road_2,
                p_c019 => l_address,
                p_c020 => l_mark_type_id,
                p_c021 => l_mark_type,
                p_c022 => l_marking_location_id,
                p_c023 => l_marking_location,
                p_c024 => l_offset_from_mark,
                p_c025 => l_spacing_on_centre,
                p_c026 => l_hydro,
                p_n001 => l_quantity,
                p_n004 => 1,
                p_n005 => l_id);
        END IF;

    END;


    /************************************************************************************************
    /*
    /* @procedure: process_detail_rows
    /*
    /* @description: Process detail row collection and push data back into the database.
    /*             
    /* @type P_TREE_PLANTING_DETAIL_ID In Number - tree planting detail id
    /************************************************************************************************/ 
    PROCEDURE process_detail_rows(P_TREE_PLANTING_DETAIL_ID IN  BSMART_DATA.STP_TREE_PLANTING_DETAIL_ROW.TREE_PLANTING_DETAIL_ID%TYPE)
    AS
    BEGIN
      for rec in(
      select c007, c008, c009, c010, c011, c012, c013, c014, c016, c017, c018, c019, c020, c022, c024, c025, c026,  n001, n003, n004, n005
      from apex_collections
      where collection_name = G_DETAIL_COLLECTION_NAME
      )
      loop
        CASE 
        WHEN rec.n004=1 AND rec.n005 IS NULL THEN  -- New record
            BEGIN
            INSERT INTO STP_TREE_PLANTING_DETAIL_ROW (TREE_PLANTING_DETAIL_ID,
                                                RIN,
                                                ROADSIDE,
                                                BETWEEN_ROAD_1,
                                                BETWEEN_ROAD_2,
                                                ADDRESS,
                                                COMMENTS,
                                                MARK_TYPE_ID,
                                                MARKING_LOCATION_ID,
                                                OFFSET_FROM_MARK,
                                                SPACING_ON_CENTRE,
                                                HYDRO,
                                                ACTIVITY_TYPE_ID,
                                                STOCK_TYPE_ID,
                                                PLANT_TYPE_ID,
                                                SPECIES_ID,
                                                STUMP_SIZE_ID,
                                                TRANSPLANTING_DISTANCE_ID,
                                                QTY,
                                                ORDER_NO)
                                    values (P_TREE_PLANTING_DETAIL_ID,
                                            rec.c014,
                                            rec.c016,
                                            rec.c017,
                                            rec.c018,
                                            rec.c019,
                                            rec.c007,
                                            rec.c020,
                                            rec.c022,
                                            rec.c024,
                                            rec.c025,
                                            rec.c026,
                                            rec.c008,
                                            rec.c009,
                                            rec.c010,
                                            rec.c011,
                                            rec.c012,
                                            rec.c013,
                                            rec.n001,
                                            rec.n003);
            COMMIT;
            
            END;
                                        
        WHEN rec.n004=1 AND rec.n005 IS NOT NULL THEN  -- Exsiting record
        UPDATE STP_TREE_PLANTING_DETAIL_ROW SET     
            RIN                       =  rec.c014,
            ROADSIDE                  =  rec.c016,
            BETWEEN_ROAD_1            =  rec.c017,
            BETWEEN_ROAD_2            =  rec.c018,
            ADDRESS                   =  rec.c019,
            COMMENTS                  =  rec.c007,
            MARK_TYPE_ID              =  rec.c020,
            MARKING_LOCATION_ID       =  rec.c022,
            OFFSET_FROM_MARK          =  rec.c024,
            SPACING_ON_CENTRE         =  rec.c025,
            HYDRO                     =  rec.c026,
            ACTIVITY_TYPE_ID          =  rec.c008,
            STOCK_TYPE_ID             =  rec.c009,
            PLANT_TYPE_ID             =  rec.c010,
            SPECIES_ID                =  rec.c011,
            STUMP_SIZE_ID             =  rec.c012,
            TRANSPLANTING_DISTANCE_ID =  rec.c013,
            QTY                       =  rec.n001,
            ORDER_NO                  =  rec.n003
            WHERE ID = rec.n005;
 
        WHEN rec.n004=0 AND rec.n005 IS NOT NULL THEN -- Deleted record

            BEGIN
            DELETE FROM STP_TREE_PLANTING_DETAIL_ROW WHERE ID=rec.n005;
            COMMIT;
            
            END;
        ELSE
        NULL;
        END CASE;
    end loop;
    END;



END STP_TPD_UTIL_PKG;