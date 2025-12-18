-- Test SQL file with a procedure that calls another procedure
-- This reproduces the CALL statement parsing bug in Piggly

CREATE OR REPLACE PROCEDURE public.update_quality_procedure(
    IN p_caller_id bigint
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    -- Simple procedure that does nothing
    RAISE NOTICE 'Called with ID: %', p_caller_id;
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.update_quality_outer(
    IN p_param_id bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $procedure$
BEGIN
    CALL public.update_quality_procedure(p_caller_id => p_param_id);
END;
$procedure$;

