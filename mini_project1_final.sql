-- 서론 : 문제점

-- 원하는 것을 실제로 준 상품은 ?
select a.brand, a.product_name '원하는 것을 실제로 준 상품', a.price_range '가격대',
       a.ranking '가격대 별 원하는 상품 순위', b.ranking '가격대 별 많이 준 상품 순위'
  from want_present a, give_present b
  where a.product_name = b.product_name
  order by 1;

-- 배송과 쿠폰 합치기 (중복 제외)
create view d_c100 as
select product_name
  from delivery100
union
select product_name
  from coupon;   -- 252

-- 배송, 쿠폰 중에 원햇지만 주지 않은 상품 갯수
select count(*)
  from d_c100
  where product_name not in (select product_name from want_present);  -- 225

select 225/252 * 100;  -- 89.3%
  
-- 받고 싶어하지만 의외로 많이 선물 안 해주는 품목 (쿠폰)
-- select a.product_name, a.ranking "배송랭킹", b.ranking "위시랭킹", b.price_range, b.ranking - a.ranking "순위차이"
--   from coupon a 
--   inner join want_present b 
--     on a.product_name = b.product_name
--   order by 3, 5;



-- 적당한 가격대는?

-- 가격대별 선호도 
select a.price_range, count(*)
  from (select ranking, product_name, price, brand,
		   if(price < 10000, '1만원미만', if(price < 30000, '1_2만원대', if(price < 50000, '3_4만원대', '5만원이상'))) price_range
		  from delivery100) a
  group by a.price_range
  order by 2 desc;
  
  -- 결론) 가격대는 1~2만원(여유x), 3~4만원(여유o)

  
-- 성향별 최고 브랜드는?
  
-- 많이 선물한 교환권은 각 카테고리별로 나와있음
-- 그렇다면 이때 각 카테고리에서 가장 많은 비율을 차지하고 있는 브랜드는?  
with a as (
select b.category cate, b.brand br, count(b.brand) num
  from coupon a
  left join cate_br b
    on a.brand = b.brand
  where b.category is not null
  group by b.category, b.brand
  ),
b as (
select b.category cate, count(b.brand) num
  from coupon a
  left join cate_br b
    on a.brand = b.brand
  where b.category is not null
  group by b.category
  )
select a.cate, a.br, a.num, a.num / b.num * 100 pct,
rank() over (partition by a.cate order by a.num / b.num * 100 desc) ranking
  from a, b
  where a.cate = b.cate;

-- 카테고리별 원하는 상품과 일치하는 브랜드
select cate, br, count(br) num
  from (select a.product_name pro_name, a.ranking ranks, b.category cate, b.brand br
		  from want_present a
		  left join cate_br b
			on a.brand = b.brand
		  where b.category is not null) a
  group by cate, br;
  
 create view raterank as 
  with a as (
select b.category cate, b.brand br, count(b.brand) num
  from coupon a
  left join cate_br b
    on a.brand = b.brand
  where b.category is not null
  group by b.category, b.brand
  ),
b as (
select b.category cate, count(b.brand) num
  from coupon a
  left join cate_br b
    on a.brand = b.brand
  where b.category is not null
  group by b.category
  )
select a.cate, a.br, a.num, a.num / b.num * 100 pct,
rank() over (partition by a.cate order by a.num / b.num * 100 desc) ranking
  from a, b
  where a.cate = b.cate;
  
create view cate_want as
  select cate, br, count(br) num
  from (select a.product_name pro_name, a.ranking ranks, b.category cate, b.brand br
		  from want_present a
		  left join cate_br b
			on a.brand = b.brand
		  where b.category is not null) a
  group by cate, br;

-- 카테고리별 많이 주는 선물과 원하는 선물 일치 브랜드
  select a.cate, a.br
  from raterank a, cate_want b
  where a.br = b.br
  and a.cate = b.cate;
  
-- 결론) 카페) 스벅,설빙 // 아이스크림) 배라,설빙 // 치킨) bhc,bbq,굽네 // 편의점) gs // 페밀리) 아웃백
  
  

-- 배송이냐 교환권이냐 그것이 문제로다
  
-- 필승하는 배송상품 선물
select a.product_name, b.ranking, b.price_range, a.brand
	from delivery100 a 
	inner join want_present b 
		on a.product_name = b.product_name
where b.ranking < 5
order by 3;

-- 필승하는 교환권 선물
select a.product_name, b.ranking, b.price_range, a.brand
	from coupon a 
	inner join want_present b 
		on a.product_name = b.product_name
where b.ranking < 5
order by 3;

-- 결론) 교환권 스타벅스 부드러운디저트아이스카페아메리카노T2잔부드러운생크림카스텔라 - 무난
-- 이유) 위에서 고른 가격대와 성향별 최고 브랜드를 두개 다 만족하는 선물