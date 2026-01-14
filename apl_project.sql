# memanggil data
SELECT *
FROM `proyekakhir-dataanalystic.apl_project.country_data`;

##### BAB 1: Pemindaian Awal (Global Overview) #####
# Tugas 1.1 (Profil Kesenjangan Ekonomi)
SELECT
       COUNT(*) total_negara,
       MIN(gdpp) gdp_minimal,
       MAX(gdpp) gdp_maksimal
FROM `proyekakhir-dataanalystic.apl_project.country_data`;

# negara dengan GDP terendah
SELECT country, gdpp
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY gdpp ASC
LIMIT 1;

# negara dengan GDP tertinggi
SELECT country, gdpp
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY gdpp DESC
LIMIT 1;


# Tugas 1.2 (Analisis Tingkat Fertilitas)
SELECT country, total_fer
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY total_fer DESC
LIMIT 5;


# Tugas 1.3 (Analisis Harapan Hidup)
SELECT country, life_expec
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY life_expec ASC
LIMIT 5;


# Tugas 1.4 (Identifkasi Inflasi Tinggi)
SELECT country, inflation
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY inflation DESC
LIMIT 5;


# Tugas 1.5 (Hubungan Pendapatan dan Kesehatan)
# 5 negara dengan pendapatan tertinggi
WITH top_income AS (
    SELECT country, income, child_mort
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
    WHERE income IS NOT NULL
    ORDER BY income DESC
    LIMIT 5
),

# 5 negara dengan angka kematian anak terendah
low_child_mort AS (
    SELECT country, income, child_mort
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
    WHERE child_mort IS NOT NULL
    ORDER BY child_mort ASC
    LIMIT 5
)
SELECT country, income, child_mort,'Pendapatan Tertinggi' AS kategori
FROM top_income
UNION ALL
SELECT country, income, child_mort,'Kematian Anak Terendah' AS kategori
FROM low_child_mort;



##### BAB 2: Menyingkap Fakta Tersembunyi (Feature Engineering) #####
# Tugas 2.1 (Konversi Anggaran Kesehatan ke USD)
SELECT country, 
       health, 
       gdpp, 
       ROUND(((health/100)* gdpp),2) health_spending
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY health_spending;


# Tugas 2.2 (Analisis Neraca Perdagangan)
SELECT country, 
       exports, 
       imports, 
       ROUND(((exports-imports)*(gdpp/100)),2) trade_balance
FROM `proyekakhir-dataanalystic.apl_project.country_data`
ORDER BY trade_balance;


# Tugas 2.3 (Perbandingan Produksi vs Pendapatan)
SELECT
  country,
  gdpp,
  income,
  ROUND(gdpp - income, 3) gdp_income_gap
FROM `proyekakhir-dataanalystic.apl_project.country_data`;



##### BAB 3: Segmentasi Mendalam (Data Grouping) #####
# Tugas 3.1 (Segmentasi Tingkat Ekonomi)
SELECT
      CASE
            WHEN gdpp <2000 THEN "Rendah"
            WHEN gdpp BETWEEN 2000 AND 10000 THEN "Menengah"
            ELSE "Tinggi"
      END economy_level,
      ROUND(AVG(child_mort), 4) avg_child_mort,
      COUNT(country) total_countries
FROM `proyekakhir-dataanalystic.apl_project.country_data`
GROUP BY economy_level;


# Tugas 3.2 (Segmentasi Tingkat Fertilitas)
SELECT
      CASE
            WHEN total_fer <2 THEN "Rendah"
            WHEN total_fer BETWEEN 2 AND 4 THEN "Menengah"
            ELSE "Tinggi"
      END fertility_level,
      ROUND(AVG(income), 4) avg_income,
      COUNT(country) total_countries
FROM `proyekakhir-dataanalystic.apl_project.country_data`
GROUP BY fertility_level
HAVING fertility_level = "Tinggi";

# Tugas 3.3 (Dampak Inflasi terhadap Harapan Hidup)
SELECT
      CASE
            WHEN inflation <5 THEN "Stabil"
            WHEN inflation BETWEEN 5 AND 15 THEN "Moderat"
            ELSE "Tinggi"
      END inflation_level,
      ROUND(AVG(life_expec), 4) avg_life_expec,
      COUNT(country) total_countries
FROM `proyekakhir-dataanalystic.apl_project.country_data`
GROUP BY inflation_level
ORDER BY avg_life_expec DESC;



##### BAB 4: Identifikasi Zona Kritis (Data Filtering) #####
# Tugas 4.1 (Menentukan Ambang Batas Statistik)
# persentil ke-25 dari gdpp (ambang batas kemiskinan)
SELECT
  APPROX_QUANTILES(gdpp, 100)[OFFSET(25)] p25_gdpp
FROM `proyekakhir-dataanalystic.apl_project.country_data`;

# persentil ke-75 dari angka kematian anak (ambang batas kritis kesehatan)
SELECT
  APPROX_QUANTILES(child_mort, 100)[OFFSET(75)] p75_child_mort
FROM `proyekakhir-dataanalystic.apl_project.country_data`;

# gabungan
SELECT
  APPROX_QUANTILES(gdpp, 100)[OFFSET(25)] p25_gdpp,
  APPROX_QUANTILES(child_mort, 100)[OFFSET(75)] p75_child_mort
FROM `proyekakhir-dataanalystic.apl_project.country_data`;

select
      percentile_cont(gdpp, 0.25) over() ambang_batas_kemiskinan,
      percentile_cont(child_mort, 0.75) over() ambang_batas_krisis_kesehatan
from `proyekakhir-dataanalystic.apl_project.country_data`
limit 1;


# Tugas 4.2 (Filtrasi Negara Prioritas)
SELECT
  country,
  gdpp,
  child_mort
FROM `proyekakhir-dataanalystic.apl_project.country_data`
#WHERE gdpp < 1330
  #AND child_mort > 62.1
  where gdpp IS NOT NULL
  AND child_mort IS NOT NULL
ORDER BY child_mort DESC, gdpp ASC;



##### BAB 5: Keputusan Akhir dan Visualisasi #####
# Tugas 5.1 (Pemilihan 10 Negara Prioritas)
SELECT
  country,
  gdpp,
  child_mort,
  life_expec
FROM `proyekakhir-dataanalystic.apl_project.country_data`
WHERE
  gdpp < (
    SELECT
      APPROX_QUANTILES(gdpp, 100)[OFFSET(25)]
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
  )
  AND
  child_mort > (
    SELECT
      APPROX_QUANTILES(child_mort, 100)[OFFSET(75)]
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
  )
ORDER BY life_expec ASC
LIMIT 10;

select country, health, child_mort, gdpp, round(((health/100)* gdpp),2) health_spending,exports, imports, round(((exports-imports)*(gdpp/100)),2) trade_balance, income, round((gdpp-income),2)wealth_gap,
life_expec,
from `proyekakhir-dataanalystic.apl_project.country_data`
where
      gdpp<= 1310
      and child_mort>62.1
order by life_expec asc
limit 10;

SELECT
  country,
  gdpp,
  child_mort,
  life_expec
FROM `proyekakhir-dataanalystic.apl_project.country_data`
WHERE
  gdpp < (
    SELECT
      APPROX_QUANTILES(gdpp, 100)[OFFSET(25)]
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
  )
  AND
  child_mort > (
    SELECT
      APPROX_QUANTILES(child_mort, 100)[OFFSET(75)]
    FROM `proyekakhir-dataanalystic.apl_project.country_data`
  )
ORDER BY life_expec ASC
LIMIT 10;