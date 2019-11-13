#!/bin/bash

#----------------------------------------------------------------------------
# Lyceum DDL to JDL
#
# Dado um arquivo SQL com DDL de tabelas, gera um arquivo
# JDL (JHipster Data Language).
#----------------------------------------------------------------------------

INPUT_FILE=$1

# Lista de tipos do Lyceum apontando para valores válidos no JDL
declare -A LY_DATA_TYPES=(
  ["T_TIPO_COMPOSICAO"]="String"
  ["T_SIMNAO"]="String"
  ["T_SEXO"]="String"
  ["T_HORA"]="Instant"
  ["T_DATA"]="Instant"
  ["T_PERCENTUAL54"]="BigDecimal"
  ["T_PERCENTUAL52"]="BigDecimal"
  ["T_PERCENTUAL"]="BigDecimal"
  ["T_DECIMAL_PRECISO"]="BigDecimal"
  ["T_DECIMAL_MEDIO_PRECISO6"]="BigDecimal"
  ["T_DECIMAL_MEDIO_PRECISO"]="BigDecimal"
  ["T_DECIMAL_MEDIO"]="BigDecimal"
  ["T_IMAGEM"]="ImageBlob"
  ["T_VALOR_INTEIRO"]="Integer"
  ["T_SEMESTRE2"]="Integer"
  ["T_SEMESTRE"]="Integer"
  ["T_NUMFUNC"]="Long"
  ["T_NUMERO_PEQUENO"]="Integer"
  ["T_NUMERO_GRANDE"]="Long"
  ["T_NUMERO"]="Long"
  ["T_MES"]="Integer"
  ["T_AULA"]="Integer"
  ["T_ANO"]="Integer"
  ["T_UF"]="String"
  ["T_TIPO_TAXA"]="String"
  ["T_TIPO_NOTA"]="String"
  ["T_TIPO_AVALIACAO"]="String"
  ["T_TELEFONE"]="String"
  ["T_SIT_MATRICULA"]="String"
  ["T_SIT_MATGRADE"]="String"
  ["T_SIT_HISTMATRICULA"]="String"
  ["T_SIT_CHEQUE"]="String"
  ["T_SIT_CANDIDATO_VEST"]="String"
  ["T_SIT_ALUNO"]="String"
  ["T_SITUACAO_CONTRATO"]="String"
  ["T_SISTEMA"]="String"
  ["T_SALA_ESPECIAL"]="String"
  ["T_RELATORIO"]="String"
  ["T_REGIME"]="String"
  ["T_PROVA10"]="String"
  ["T_PROVA"]="String"
  ["T_PISPASEP"]="String"
  ["T_ORIGEM_ESTORNO"]="String"
  ["T_OCORRENCIA_FALTA"]="String"
  ["T_NOME_MED"]="String"
  ["T_NOME_LONGO"]="String"
  ["T_MOTIVO"]="String"
  ["T_MNEMONICO6"]="String"
  ["T_MNEMONICO"]="String"
  ["T_MENSAGEM"]="String"
  ["T_GRUPO_RELATORIO"]="String"
  ["T_FALTA"]="String"
  ["T_E_MAIL"]="String"
  ["T_ESTADO_CIVIL"]="String"
  ["T_CPF"]="String"
  ["T_CODIGO2"]="String"
  ["T_CODIGO"]="String"
  ["T_CGC"]="String"
  ["T_CEP"]="String"
  ["T_ALFA_HUGE"]="String"
  ["T_ALFASMALL_17"]="String"
  ["T_ALFASMALL_10"]="String"
  ["T_ALFASMALL"]="String"
  ["T_ALFAMEDIUM"]="String"
  ["T_ALFALARGE"]="String"
  ["T_ALFAEXTRALARGE"]="String"
  ["T_ALFA7000"]="String"
  ["T_ALFA500"]="String"
  ["varchar"]="String"
  ["char"]="String"
  ["numeric"]="BigDecimal"
  ["datetime"]="Instant"
)

OPTIONAL_ENDING="(\(.*\))?"

# Inicializa CMD com "corner case"
CMD="s/numeric\(1,0\)/Integer/g;"

echo "Replacing data types..."
for TYPE in "${!LY_DATA_TYPES[@]}";
do
  #echo "Replacing type '$TYPE' with '${LY_DATA_TYPES[$TYPE]}'"
  CMD="${CMD}s/\b$TYPE\b$OPTIONAL_ENDING/${LY_DATA_TYPES[$TYPE]}/g;"
done;

sed -r "$CMD" $INPUT_FILE > out.txt

# Lista com outros replacements necessários
declare -A LY_REPLACEMENTS=(
  ["\--.*"]=""
  ["CONSTRAINT.*"]=""
  ["CREATE\sINDEX.*"]=""
  ["CREATE\sUNIQUE.*"]=""
  ["NOT\sNULL"]="required"
  ["DEFAULT\s\(.*\)"]=""
  ["\sGO(;)?"]=""
  ["CREATE TABLE Desenv_Lyceum.dbo."]="entity "
  ["\($"]="{"
  ["\)$"]="}"
  ["LY_"]=""
)

CMD=""

echo "Replacing syntax..."
for REPL in "${!LY_REPLACEMENTS[@]}";
do
  #echo "Replacing '$REPL' with '${LY_REPLACEMENTS[$REPL]}'"
  CMD="${CMD}s/$REPL/${LY_REPLACEMENTS[$REPL]}/g;"
done;

# remove linhas vazias
CMD="${CMD}/^\s*$/d;"

# aplica camelcase em colunas com underline
CMD="${CMD}s/^ *[^ ]+/\L&/g;s/_(.)/\U\1/g;"

sed -r "$CMD" out.txt > output.jdl
rm out.txt

# Torna entity names camel case
#CMD="s/(CREATE TABLE Desenv_Lyceum.dbo.)(.*)(\s\()/entity \L\2\3/g;s/_(.)/\U\1/g;"

echo "Done."
