select null as "filename",
cursor(
  select 
  cursor(
    select distinct 
           w.MUNICIPALITY as "MUN",
           :P0_YEAR ||' - '|| w.CONTRACT_NUM as "CON",
           w.ROADSIDE as "RD",
           cursor(
              select distinct l.TAG_NUMBER as "TNO",
                              l.TAG_COLOR as "TCO",
                              l.SPECIES as "SPEC",
                              l.CURRENTHEALTH as "HEL"
              from STP_TREE_LOCATION_V l
              join STP_WARRANTY_PRINT_V w1 on w1.TREEID = l.TREEID
              where convert(w1.MUNICIPALITY, 'AL16UTF16', 'AL32UTF8') = w.MUNICIPALITY
              and w1.CONTRACT_NUM = w.CONTRACT_NUM
              and convert(w1.ROADSIDE, 'AL16UTF16', 'AL32UTF8') = w.ROADSIDE
              and w1.CONTRACTYEAR = :P0_YEAR
              and w1.WARRANTY_TYPE_ID = :P119_WTYPE
              order by l.TAG_NUMBER
           ) "ITEMS",
           cursor(
              select distinct count(distinct l.TAG_NUMBER) as "TOT"
              from STP_TREE_LOCATION_V l
              join STP_WARRANTY_PRINT_V w1 on w1.TREEID = l.TREEID
              where convert(w1.MUNICIPALITY, 'AL16UTF16', 'AL32UTF8') = w.MUNICIPALITY
              and w1.CONTRACT_NUM = w.CONTRACT_NUM
              and convert(w1.ROADSIDE, 'AL16UTF16', 'AL32UTF8') = w.ROADSIDE
              and w1.CONTRACTYEAR = :P0_YEAR
              and w1.WARRANTY_TYPE_ID = :P119_WTYPE
              order by l.TAG_NUMBER
           ) "QTY"
           from STP_WARRANTY_PRINT_V w  
           where exists(
              select distinct l.TAG_NUMBER as "TNO",
                              l.TAG_COLOR as "TCO",
                              l.SPECIES as "SPEC",
                              l.CURRENTHEALTH as "HEL"
              from STP_TREE_LOCATION_V l
              join STP_WARRANTY_PRINT_V w1 on w1.TREEID = l.TREEID
              where w1.MUNICIPALITY = w.MUNICIPALITY
              and w1.CONTRACT_NUM = w.CONTRACT_NUM
              and w1.ROADSIDE = w.ROADSIDE
              and w1.CONTRACTYEAR = :P0_YEAR
              and w1.WARRANTY_TYPE_ID = :P119_WTYPE
           )
           group by w.MUNICIPALITY, w.CONTRACT_NUM, w.ROADSIDE
           order by 1, 2, 3
        ) "OUTER"
        from dual
  ) "data"
from dual


