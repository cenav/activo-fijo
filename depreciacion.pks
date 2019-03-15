CREATE OR REPLACE PACKAGE depreciacion AS
    PROCEDURE procesa(p_periodo_ano PLS_INTEGER, p_periodo_mes PLS_INTEGER);
    PROCEDURE elimina(p_periodo_ano PLS_INTEGER, p_periodo_mes PLS_INTEGER);
END depreciacion;