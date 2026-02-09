-- -- macros/get_custom_schema.sql

-- {% macro generate_schema_name(custom_schema_name, node) -%}
--     {%- set default_schema = target.schema -%}
    
--     {%- if target.name == 'prod' -%}
--         {# PRODUCTION: Use exact custom schema name #}
--         {%- if custom_schema_name is none -%}
--             {{ default_schema }}
--         {%- else -%}
--             {{ custom_schema_name | trim }}
--         {%- endif -%}
    
--     {%- else -%}
--         {# DEVELOPMENT: Everything goes to default schema (dev_dbt_dev) #}
--         {{ default_schema }}
    
--     {%- endif -%}
-- {%- endmacro %}