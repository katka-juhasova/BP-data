-- based on https://gist.github.com/wandersoncferreira/657d4aff804205c2e035b5d4df6e63be

function digito_verificador(random_cnpj, pesos)
   local table_check = {}
   for i, p in ipairs(pesos) do
      table_check[i] = random_cnpj[i] * p
   end

   local sum_check = 0
   for i, p in ipairs(table_check) do
      sum_check = sum_check + p
   end

   local quociente_check = math.floor(sum_check / 11)
   local resto_check = sum_check % 11

   local dv
   if resto_check <= 2 then
      dv = 0
   else
      dv = 11 - resto_check
   end
   return dv
end

function gerar_cnpj()
   math.randomseed(os.time())

   cnpj_sem_dv = {}
   for i = 1, 12 do
      if i > 8 and i < 12 then
         cnpj_sem_dv[i] = 0
      elseif i == 12 then
         cnpj_sem_dv[i] = 1
      else
         cnpj_sem_dv[i] = math.random(9)
      end
   end

   -- calcular primeiro digito verificador
   local pesos1 = {5,4,3,2,9,8,7,6,5,4,3,2}
   local dv1 = digito_verificador(cnpj_sem_dv, pesos1)
   table.insert(cnpj_sem_dv, dv1)

   -- calculando o segundo digito verificador
   local pesos2 = {6,5,4,3,2,9,8,7,6,5,4,3,2}
   local dv2 = digito_verificador(cnpj_sem_dv, pesos2)
   table.insert(cnpj_sem_dv, dv2)

   local cnpj = ""
   for _, v in pairs(cnpj_sem_dv) do
      cnpj = cnpj .. v
   end
   return cnpj
end

function gerar_cnpj_formatado()
   local cnpj = gerar_cnpj()
   local cnpj_fmt = "" .. string.sub(cnpj, 0, 2) .. "." ..
      string.sub(cnpj, 3, 5) .. "." ..
      string.sub(cnpj, 6, 8) .. "/" ..
      string.sub(cnpj, 9, 12) .. "-" ..
      string.sub(cnpj, 13, 15)
   return cnpj_fmt
end


function gerar_cpf()
   math.randomseed(os.time())

   cpf_sem_dv = {}
   for i = 1, 9 do
      cpf_sem_dv[i] = math.random(9)
   end

   -- calcular primeiro digito verificador
   local pesos1 = {10, 9, 8, 7, 6, 5, 4, 3, 2}
   local dv1 = digito_verificador(cpf_sem_dv, pesos1)
   table.insert(cpf_sem_dv, dv1)

   -- calculando o segundo digito verificador
   local pesos2 = {11,10,9,8,7,6,5,4,3,2}
   local dv2 = digito_verificador(cpf_sem_dv, pesos2)
   table.insert(cpf_sem_dv, dv2)

   local cpf = ""
   for _, v in pairs(cpf_sem_dv) do
      cpf = cpf .. v
   end
   return cpf
end


function gerar_cpf_formatado()
   local cpf = gerar_cpf()
   local cpf_fmt = "" .. string.sub(cpf, 0, 3) .. "." ..
      string.sub(cpf, 4, 6) .. "." ..
      string.sub(cpf, 7, 9) .. "-" ..
      string.sub(cpf, 10, 12)
   return cpf_fmt
end
