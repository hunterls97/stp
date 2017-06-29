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
               (w.warranty_type_id = :P114_WTYPE or w.warranty_type_id is null) and -- remove is null from or condition when stp has correct data
               convert(w.contract_num, 'AL16UTF16', 'AL32UTF8') = w1.contract_num
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
        where exists(
          select w.health,
                 w.contract_num
                 from STP_WARRANTY_PRINT_V w
                 where w.species is not null and
                 w.status = 'Active' and 
                 w.CONTRACTOPERATION in (1, 3) and
                 w.yearplanted = :p0_year 
                group by w.health, w.contract_num
        )
      ) "MUNICIPALITIES"
      from STP_WARRANTY_PRINT_V w1
      where w1.municipality is not null
      and w1.municipality<>'Durham'
      and exists(
          select w.health,
                 w.contract_num
                 from STP_WARRANTY_PRINT_V w
                 where w.species is not null and
                 w.status = 'Active' and 
                 w.CONTRACTOPERATION in (1, 3) and
                 w.yearplanted = :p0_year
                group by w.health, w.contract_num
        )
      group by w1.contract_num
      order by w1.contract_num
  ) "OUTER"
  from dual
) "data"
from dual 