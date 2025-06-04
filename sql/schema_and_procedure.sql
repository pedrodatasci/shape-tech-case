-- Cria o schema
CREATE SCHEMA silver;

-- Procedure de Upsert
CREATE OR REPLACE PROCEDURE merge_equipment_failures()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remover duplicatas antigas
    DELETE FROM silver.equipment_failures
    USING staging.equipment_failures AS s
    WHERE silver.equipment_failures.equipment_id = s.equipment_id
      AND silver.equipment_failures.sensor_id = s.sensor_id
      AND silver.equipment_failures.timestamp = s.timestamp;

    -- Inserir dados novos
    INSERT INTO silver.equipment_failures
    SELECT * FROM staging.equipment_failures;
END;
$$;