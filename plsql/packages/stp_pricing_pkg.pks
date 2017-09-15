create or replace package             stp_pricing_util_pkg as 

    /************************************************************************************************
    /*
    /* @file_name: stp_pricing_util_pkg.pks
    /* @author: Gary Kang
    /*  
    /* @description: Pricing utility functions for STP applications
    /*
    /************************************************************************************************/ 
    
    -- Query to update estimated price.
    G_UPDATE_RATE_QUERY varchar2(1000) := 'UPDATE BSMART_DATA.STP_PRICE SET PRICE_EST= LAST_YEAR_PRICE*{RATE} WHERE YEAR={YEAR}';


    procedure setup_default_pricing( p_year in number);


    procedure manage_pricing_record(p_year            in number,
                                    p_type_id            in number,
                                    p_stock_type_id      in number,
                                    p_plant_type_id      in number,
                                    p_species_id         in number,
                                    p_stumping_size_id   in number,
                                    p_transp_dis_id      in number,
                                    p_mode            in varchar2);
                                

    procedure save_and_apply_inc_rate( p_year in number,
                                       p_rate in number);


    function get_inc_rate(p_year in number) return number;


    procedure load_last_year_price ( p_year in number);



end stp_pricing_util_pkg;