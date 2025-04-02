

												/*===========================================================
													🔍 DATA STRUCTURE EXPLORATION & TYPE CORRECTION

												This script includes:
												- Exploration of the dataset structure
												- Inspection of column data types (PostgreSQL & MySQL)
												- Correction of column data types for proper analysis
												===========================================================*/*/

/*--------------------------------------------------
🔴1.A) EXPLORE THE DATA STRUCTURE (COLUMN TYPES).
---------------------------------------------------*/

	🔵1.A.1)--checking all data types at once (on postegree)

	from information_schema.columns
	select column_name, data_type --checking all data types at once (on postegree)
	from information_schema.columns
	where table_name = 'global_land_temp_country';

	🔵1.A.2)--checking all data types at once (on MySQL)

	describe global_land_temp_country; 



/*-------------------------
🔴1.B) CORRECT DATATYPES
--------------------------*/

	🔵1.B.1)
	ALTER TABLE global_land_temp_country
	ALTER averagetemp 
	TYPE float USING averagetempuncertainty::FLOAT;

	🔵1.B.2)
	ALTER TABLE global_land_temp_country 
	ALTER averagetempuncertainty
	TYPE float USING averagetempuncertainty::FLOAT;
