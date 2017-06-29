with accepted_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    t.munid as "MU",
    count(t.species) as "ASUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Accept' and t.yearplanted = :p0_year and t.status = 'Active'
    --and t.species is not null
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
                 w.speciesid
                 from STP_WARRANTY_PRINT_V w
                 where w.species is not null and
                 w.status = 'Active' and 
                 w.CONTRACTOPERATION in (1, 3) and
                 w.yearplanted = :p0_year and
                (w.warranty_type_id = :P114_WTYPE or w.warranty_type_id is null)
                group by w.species, w.speciesid
        )
      group by w1.municipality, w1.munid
      order by w1.municipality
  ) "OUTER"
  from dual
) "data"
from dual 