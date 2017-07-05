create or replace package body                                                                                     STP_WARRANTY_PKG as
    
    function AOP_municipality_report return varchar2
    as
      l_return clob;
    begin
      l_return := q'[
        with accepted_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    t.munid as "MU",
    count(t.species) as "ASUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Accept' and t.yearplanted = :p0_year and t.status = 'Active'
    group by t.speciesid, t.species, t.munid
    order by 2
),

rejected_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    t.munid as "MU",
    count(t.species) as "RSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Reject' and t.yearplanted = :p0_year and t.status = 'Active'
    and t.species is not null
    group by t.speciesid, t.species, t.munid
),

missing_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    t.munid as "MU",
    count(t.species) as "MSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Missing Tree' and t.yearplanted = :p0_year
    and t.species is not null
    group by t.speciesid, t.species, t.munid
)

select null as "filename",
cursor(
  select 
  cursor(
    select w1.municipality as "MUN",
    cursor(
   select 
     cursor(
        select w.species as "SPEC", 
               w.speciesid,
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
               nvl(acsum.ASUM, 0) as "ACC",
               nvl(rjsum.rsum, 0) as "REJ",
               nvl(misum.msum, 0) as "MISS"
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.SPECIESID = w.SPECIESID and acsum.mu = w.munid
               left join rejected_sum rjsum on rjsum.SPECIESID = w.SPECIESID and rjsum.mu = w.munid
               left join missing_sum misum on misum.SPECIESID = w.SPECIESID and misum.mu = w.munid
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P114_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               convert(w.municipality, 'AL16UTF16', 'AL32UTF8') = w1.municipality
               group by w.species, w.speciesid, w.munid, acsum.asum, rjsum.rsum, misum.msum
        order by w.Species
        ) "SLIST",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.munid) + 
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.munid) + 
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.munid) as "TOTTOT",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.munid) as "ATOT",
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.munid) as "RTOT",
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.munid) as "MTOT"
        from dual
        where exists(
          select w.species as "SPEC", 
                 w.speciesid
                 from STP_WARRANTY_PRINT_V w
                 where w.species is not null and
                 w.status = 'Active' and 
                 w.CONTRACTOPERATION in (1, 3) and
                 w.yearplanted = :p0_year and
                (w.warranty_type_id = :P114_WTYPE or w.warranty_type_id is null)
                group by w.species, w.speciesid
        )
      ) "MUNICIPALITIES"
      from STP_WARRANTY_PRINT_V w1
      where w1.municipality is not null
      and w1.municipality<>'Durham'
      and exists(
           select w.species as "SPEC", 
               w.speciesid,
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
               nvl(acsum.ASUM, 0) as "ACC",
               nvl(rjsum.rsum, 0) as "REJ",
               nvl(misum.msum, 0) as "MISS"
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.SPECIESID = w.SPECIESID and acsum.mu = w.munid
               left join rejected_sum rjsum on rjsum.SPECIESID = w.SPECIESID and rjsum.mu = w.munid
               left join missing_sum misum on misum.SPECIESID = w.SPECIESID and misum.mu = w.munid
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P114_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               w.municipality = w1.municipality
               group by w.species, w.speciesid, w.munid, acsum.asum, rjsum.rsum, misum.msum
        )
      group by w1.municipality, w1.munid
      order by w1.municipality
  ) "OUTER"
  from dual
) "data"
from dual 	
      ]';
      
      return l_return;
    end;
    
    function AOP_health_report return varchar2
    as
      l_return clob;
   begin
      l_return := q'[
          with accepted_sum as(
    select t.health as "HEALTH", 
    t.munid as "MU",
    count(t.health) as "ASUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Accept' and t.yearplanted = :p0_year and t.status = 'Active' 
    and t.species is not null
    group by t.health, t.munid
    order by 2
),

rejected_sum as(
    select t.health as "HEALTH",  
    t.munid as "MU",
    count(t.health) as "RSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Reject' and t.yearplanted = :p0_year and t.status = 'Active'
    and t.species is not null
    group by t.health, t.munid
),

missing_sum as(
    select t.health as "HEALTH", 
    t.munid as "MU",
    count(t.health) as "MSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Missing Tree' and t.yearplanted = :p0_year
    and t.species is not null
    group by t.health, t.munid
)

select null as "filename",
cursor(
  select 
  cursor(
    select w1.municipality as "MUN",
    cursor(
   select 
     cursor(
        select w.health ||' - '|| case w.health 
        when 1 then 'Good'
        when 2 then 'Satisfactory'
        when 3 then 'Potential Trouble'
        when 4 then 'Declining'
        when 5 then 'Death Immenent'
        when 6 then 'Dead'
        else null end as "HELRAT", 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
               nvl(acsum.ASUM, 0) as "ACC",
               nvl(rjsum.rsum, 0) as "REJ",
               nvl(misum.msum, 0) as "MISS"
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.health = w.health and acsum.mu = w.munid
               left join rejected_sum rjsum on rjsum.health = w.health and rjsum.mu = w.munid
               left join missing_sum misum on misum.health = w.health and misum.mu = w.munid
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P115_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               convert(w.municipality, 'AL16UTF16', 'AL32UTF8') = w1.municipality
               group by w.health, w.munid, acsum.asum, rjsum.rsum, misum.msum
               order by w.health
        ) "SLIST",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.munid) + 
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.munid) + 
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.munid) as "TOTTOT",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.munid) as "ATOT",
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.munid) as "RTOT",
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.munid) as "MTOT" -- 
        from dual
        where exists(
          select w.health,
                 w.munid
                 from STP_WARRANTY_PRINT_V w
                 where w.species is not null and
                 w.status = 'Active' and 
                 w.CONTRACTOPERATION in (1, 3) and
                 w.yearplanted = :p0_year 
                group by w.health, w.munid
        )
      ) "MUNICIPALITIES"
      from STP_WARRANTY_PRINT_V w1
      where w1.municipality is not null
      and w1.municipality<>'Durham'
      and exists(
            select w.health ||' - '|| case w.health 
        when 1 then 'Good'
        when 2 then 'Satisfactory'
        when 3 then 'Potential Trouble'
        when 4 then 'Declining'
        when 5 then 'Death Immenent'
        when 6 then 'Dead'
        else null end as "HELRAT", 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
               nvl(acsum.ASUM, 0) as "ACC",
               nvl(rjsum.rsum, 0) as "REJ",
               nvl(misum.msum, 0) as "MISS"
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.health = w.health and acsum.mu = w.munid
               left join rejected_sum rjsum on rjsum.health = w.health and rjsum.mu = w.munid
               left join missing_sum misum on misum.health = w.health and misum.mu = w.munid
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P115_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               w.municipality = w1.municipality
               group by w.health, w.munid, acsum.asum, rjsum.rsum, misum.msum
        )
      group by w1.municipality, w1.munid
      order by w1.municipality
  ) "OUTER"
  from dual
) "data"
from dual 
      ]';
      
      return l_return;
   end;
   
   function AOP_contract_report return varchar2
   as
    l_return clob;
   begin
    l_return := q'[
     with accepted_sum as(
    select t.health as "HEALTH", 
    t.contract_num as "MU",
    count(t.health) as "ASUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Accept' and t.yearplanted = :p0_year and t.status = 'Active' 
    and t.species is not null
    group by t.health, t.contract_num
    order by 2
),

rejected_sum as(
    select t.health as "HEALTH",  
    t.contract_num as "MU",
    count(t.health) as "RSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Reject' and t.yearplanted = :p0_year and t.status = 'Active'
    and t.species is not null
    group by t.health, t.contract_num
),

missing_sum as(
    select t.health as "HEALTH", 
    t.contract_num as "MU",
    count(t.health) as "MSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Missing Tree' and t.yearplanted = :p0_year
    and t.species is not null
    group by t.health, t.contract_num
)

select null as "filename",
cursor(
  select 
  cursor(
    select w1.contract_num,
    :p0_year ||' - '|| to_char(w1.contract_num, '000') as "CON",
    cursor(
   select 
     cursor(
        select w.health ||' - '|| case w.health 
        when 1 then 'Good'
        when 2 then 'Satisfactory'
        when 3 then 'Potential Trouble'
        when 4 then 'Declining'
        when 5 then 'Death Immenent'
        when 6 then 'Dead'
        else null end as "HELRAT", 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
               nvl(acsum.ASUM, 0) as "ACC",
               nvl(rjsum.rsum, 0) as "REJ",
               nvl(misum.msum, 0) as "MISS"
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.health = w.health and acsum.mu = w.contract_num
               left join rejected_sum rjsum on rjsum.health = w.health and rjsum.mu = w.contract_num
               left join missing_sum misum on misum.health = w.health and misum.mu = w.contract_num
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P116_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               w.contract_num = w1.contract_num
               group by w.health, w.contract_num, acsum.asum, rjsum.rsum, misum.msum
               order by w.health
        ) "SLIST",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.contract_num) + 
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.contract_num) + 
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.contract_num) as "TOTTOT",
        (select nvl(sum(a.ASUM), 0) from accepted_sum a where a.mu = w1.contract_num) as "ATOT",
        (select nvl(sum(r.RSUM), 0) from rejected_sum r where r.mu = w1.contract_num) as "RTOT",
        (select nvl(sum(m.MSUM), 0) from missing_sum m where m.mu = w1.contract_num) as "MTOT"
        from dual
      ) "CONTRACTS"
      from STP_WARRANTY_PRINT_V w1
      where w1.municipality is not null
      and w1.municipality<>'Durham'
      and exists(
          select w.health 
               from STP_WARRANTY_PRINT_V w
               left join accepted_sum acsum on acsum.health = w.health and acsum.mu = w.contract_num
               left join rejected_sum rjsum on rjsum.health = w.health and rjsum.mu = w.contract_num
               left join missing_sum misum on misum.health = w.health and misum.mu = w.contract_num
               where w.species is not null and 
               (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0))<>0 and
               w.status = 'Active' and 
               w.CONTRACTOPERATION in (1, 3) and
               w.yearplanted = :p0_year and
               (w.warranty_type_id = :P116_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               w.contract_num = w1.contract_num
               group by w.health, w.contract_num, acsum.asum, rjsum.rsum, misum.msum
      )
      group by w1.contract_num
      order by w1.contract_num
  ) "OUTER"
  from dual
) "data"
from dual 
    ]';
    
    return l_return;
   end;
  
end STP_WARRANTY_PKG;