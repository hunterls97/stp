create or replace package body             stp_pricing_util_pkg as

    /* ---------------- < setup default pricing items > ---------------- */
    procedure setup_default_pricing( p_year in number)
    is
    begin
      insert into bsmart_data.stp_price 
        (year, type_id, display, measurement, description)
        select p_year, type_id, 'y', measurement, description from stp_price_default;
      
      commit;
    end;
    
    
    /* ---------------- < manage pricing record > ---------------- */
    procedure manage_pricing_record(p_year            in number,
                                    p_type_id            in number,
                                    p_stock_type_id      in number,
                                    p_plant_type_id      in number,
                                    p_species_id         in number,
                                    p_stumping_size_id   in number,
                                    p_transp_dis_id      in number,
                                    p_mode            in varchar2)
    as 
      l_count number;
    begin
      
      if p_type_id is null or p_type_id in (4, 6) then
        null;
      elsif p_mode = 'inserting' then 
        select count(*) into l_count
        from bsmart_data.stp_price
        where year = p_year and
             (p_type_id is null or type_id = p_type_id) and
            (p_stock_type_id is null or stock_type_id = p_stock_type_id) and
            (p_plant_type_id is null or plant_type_id = p_plant_type_id) and
            (p_species_id is null or species_id = p_species_id) and 
            (p_stumping_size_id is null or stumping_size_id = p_stumping_size_id) and
            (p_transp_dis_id is null or transp_dis_id = p_transp_dis_id);

        -- create new if does not exist before
        if l_count = 0 then
          insert into bsmart_data.stp_price 
          (year, type_id, stock_type_id, plant_type_id, species_id, stumping_size_id, transp_dis_id, inuse)
          values
          (p_year, p_type_id, p_stock_type_id, p_plant_type_id, p_species_id, p_stumping_size_id, p_transp_dis_id, 'y');
        else -- update the current existing one.
          update bsmart_data.stp_price set inuse = 'y'
          where year = p_year and
             (p_type_id is null or type_id = p_type_id) and
            (p_stock_type_id is null or stock_type_id = p_stock_type_id) and
            (p_plant_type_id is null or plant_type_id = p_plant_type_id) and
            (p_species_id is null or species_id = p_species_id) and 
            (p_stumping_size_id is null or stumping_size_id = p_stumping_size_id) and
            (p_transp_dis_id is null or transp_dis_id = p_transp_dis_id);
        end if;
      elsif p_mode = 'deleting' then
        select count(*) into l_count
        from bsmart_data.stp_contract_detail scd
        left join bsmart_data.stp_contract_item sci
        on sci.id = scd.contract_item_id
        where sci.status_id <> 3 and
              sci.year = p_year and
              (p_type_id is null or type_id = p_type_id) and
              (p_stock_type_id is null or stock_type_id = p_stock_type_id) and
              (p_plant_type_id is null or plant_type_id = p_plant_type_id) and
              (p_species_id is null or species_id = p_species_id) and 
              (p_stumping_size_id is null or stumping_size_id = p_stumping_size_id) and
              (p_transp_dis_id is null or transp_dis_id = p_transp_dis_id);

        -- set to not inuse if the count is 0.
        if l_count = 0  then
          update bsmart_data.stp_price set inuse = 'n'
          where year = p_year and
                (p_type_id is null or type_id = p_type_id) and
                (p_stock_type_id is null or stock_type_id = p_stock_type_id) and
                (p_plant_type_id is null or plant_type_id = p_plant_type_id) and
                (p_species_id is null or species_id = p_species_id) and 
                (p_stumping_size_id is null or stumping_size_id = p_stumping_size_id) and
                (p_transp_dis_id is null or transp_dis_id = p_transp_dis_id);
        end if;

      end if;
      null;
    end;
    
    
  /* ---------------- < save and apply price forumla > ---------------- */
  procedure save_and_apply_inc_rate( p_year in number,
                                     p_rate in number)
  as
    l_query varchar2(32000);
  begin
      -- Save increase rate.
      MERGE INTO STP_INC_RATE SIR
        USING DUAL
        ON (SIR.year = p_year)
        WHEN MATCHED THEN 
          UPDATE SET RATE = p_rate
        WHEN NOT MATCHED THEN
          INSERT (YEAR, RATE) values (p_year, p_rate);

      commit;

      -- Update data.
      l_query := stp_constant_pkg.gc_update_rate_query;
      l_query := replace(l_query, '{RATE}', to_char(p_rate));
      l_query := replace(l_query, '{YEAR}', to_char(p_year));
      execute immediate l_query;
  end;


  /* ---------------- < Get Increase Rate > ---------------- */
  function get_inc_rate(p_year in number) return number
  as
    l_result number;
  BEGIN
     select RATE into l_result from STP_INC_RATE where year = :P0_YEAR;

     RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      return null;
  END;


  /* ---------------- < load pricing for last year> -----------------*/
  procedure load_last_year_price ( p_year in number)
  as
  begin

    update stp_price sp1 set sp1.last_year_price = 
    (select sp2.unit_price
        from bsmart_data.stp_price_v sp2
        where sp1.year = sp2.year + 1 and
             (sp1.type_id is null or sp1.type_id = sp2.type_id) and
             (sp1.description is null or sp1.description = sp2.description) and
             (sp1.stock_type_id is null or sp1.stock_type_id = sp2.stock_type_id) and
             (sp1.plant_type_id is null or sp1.plant_type_id = sp2.plant_type_id) and
             (sp1.species_id is null or sp1.species_id = sp2.species_id) and 
             (sp1.stumping_size_id is null or sp1.stumping_size_id = sp2.stumping_size_id) and
             (sp1.transp_dis_id is null or sp1.transp_dis_id = sp2.transp_dis_id)) 
    where sp1.year=p_year;

    commit;
  end;




end stp_pricing_util_pkg;