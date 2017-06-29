with accepted_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    count(t.species) as "ASUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Accept' and t.yearplanted = :p0_year and t.status = 'Active'
    --and t.species is not null
    group by t.speciesid, t.species
    order by 2
),

rejected_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    count(t.species) as "RSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Reject' and t.yearplanted = :p0_year and t.status = 'Active'
    and t.species is not null
    group by t.speciesid, t.species
),

missing_sum as(
    select t.speciesid as "SPECIESID", 
    t.species as "SPECIES", 
    count(t.species) as "MSUM"
    from STP_WARRANTY_PRINT_V t
    where t.warrantyaction = 'Missing Tree' and t.yearplanted = :p0_year
    and t.species is not null
    group by t.speciesid, t.species
)

select null as "filename",
cursor(
  select cursor(
    select w.species as "SPEC", 
           w.speciesid,
           (nvl(acsum.ASUM, 0) + nvl(rjsum.rsum, 0) + nvl(misum.msum, 0)) as "TOT",
           nvl(acsum.ASUM, 0) as "ACC",
           nvl(rjsum.rsum, 0) as "REJ",
           nvl(misum.msum, 0) as "MISS"
           from STP_WARRANTY_PRINT_V w
           left join accepted_sum acsum on acsum.SPECIESID = w.SPECIESID
           left join rejected_sum rjsum on rjsum.SPECIESID = w.SPECIESID
           left join missing_sum misum on misum.SPECIESID = w.SPECIESID
           where w.species is not null and 
           acsum.ASUM is not null and
           w.status = 'Active' and 
           w.CONTRACTOPERATION in (1, 3) and
           w.yearplanted = :p0_year and
           (w.warranty_type_id = :P113_WTYPE or w.warranty_type_id is null) -- remove is null from or condition when stp has correct data
           group by w.species, w.speciesid, acsum.asum, rjsum.rsum, misum.msum
    order by w.Species
    ) "SLIST",
    (select nvl(sum(ASUM), 0) from accepted_sum) + (select nvl(sum(RSUM), 0) from rejected_sum) + (select nvl(sum(MSUM), 0) from missing_sum) as "TOTTOT",
    (select nvl(sum(ASUM), 0) from accepted_sum) as "ATOT",
    (select nvl(sum(RSUM), 0) from rejected_sum) as "RTOT",
    (select nvl(sum(MSUM), 0) from missing_sum) as "MTOT"
    from dual
) "data"
from dual