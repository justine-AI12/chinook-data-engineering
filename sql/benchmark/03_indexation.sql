-- Index créés après les mesures "sans index"
CREATE INDEX idx_invoice_big_customer ON invoice_big (customer_id);
CREATE INDEX idx_invoice_big_id       ON invoice_big (invoice_id);
CREATE INDEX idx_il_big_invoice       ON invoice_line_big (invoice_id);

ANALYZE invoice_big;
ANALYZE invoice_line_big;
