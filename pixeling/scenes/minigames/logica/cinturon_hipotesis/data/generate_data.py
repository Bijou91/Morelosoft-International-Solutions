import json

# Generar bancos completos para las 3 dificultades: Fácil (3 pasos), Normal (4 pasos), Ingeniero (5 pasos)
# Con al menos 30 preguntas por dificultad y riguroso contenido de Inducción Matemática / Lógica Proposicional.

# ----------------- FÁCIL (3 Pasos) -----------------
facil_templates = [
    {
        "prop": "1 + 2 + ... + n = n(n+1)/2",
        "s1": "Paso 1: Probar caso base n = 1: 1 = 1(2)/2 = 1",
        "s2": "Paso 2: Formular hipótesis para n = k: 1+2+...+k = k(k+1)/2",
        "s3": "Paso 3: Probar para k+1: k(k+1)/2 + (k+1) = (k+1)(k+2)/2",
        "dis": ["Probar base en n = 0 y decir que 0/0 es indeterminado", "Asumir P(k+1) para deducir P(k)", "Restar k+1 en vez de sumarlo", "Dividir ambos lados entre k", "Afirmar que 1+2+...+n = n^2"]
    },
    {
        "prop": "1 + 3 + ... + (2n-1) = n^2",
        "s1": "Paso 1: Probar caso base n = 1: 2(1)-1 = 1 y 1^2 = 1",
        "s2": "Paso 2: Hipótesis para n = k: 1+3+...+(2k-1) = k^2",
        "s3": "Paso 3: Probar k+1 sumando 2(k+1)-1: k^2 + 2k+1 = (k+1)^2",
        "dis": ["Caso base falso: 2(1)-1 = 3", "Sumar (2k+1)^2 erróneamente", "Afirmar n^2 = (n-1)^2 + 1", "Evaluar n=-1 para números naturales", "Multiplicar por 2 en vez de sumar"]
    },
    {
        "prop": "2^n > n para todo entero n >= 1",
        "s1": "Paso 1: Caso base n = 1: 2^1 = 2 > 1 (Verdadero)",
        "s2": "Paso 2: Hipótesis para n = k: 2^k > k (con k >= 1)",
        "s3": "Paso 3: Para k+1: 2^(k+1) = 2*2^k > 2k >= k+1",
        "dis": ["Caso base falso: 2^1 < 1", "Restar 1 a 2^k en el paso inductivo", "Afirmar que 2k < k+1 para todo k natural", "Dividir entre 0 en la desigualdad", "Invertir desigualdad sin multiplicar por negativo"]
    },
    {
        "prop": "3 divide a n^3 - n para todo n >= 1",
        "s1": "Paso 1: Caso base n = 1: 1^3 - 1 = 0, y 3 divide a 0",
        "s2": "Paso 2: Hipótesis para k: k^3 - k = 3m para algún entero m",
        "s3": "Paso 3: Para k+1: (k+1)^3 - (k+1) = (k^3 - k) + 3(k^2 + k) = 3(m + k^2 + k)",
        "dis": ["Caso base: 1^3 - 1 = 1 que no es múltiplo de 3", "Asumir que si 3 divide a n^3 divide a n directamente", "Desarrollo falso: (k+1)^3 = k^3 + 1", "Restar 3m arbitrariamente", "Afirmar que k^3-k siempre es primo"]
    },
    {
        "prop": "1 + 2 + 4 + ... + 2^(n-1) = 2^n - 1",
        "s1": "Paso 1: Caso base n = 1: 2^(1-1) = 1 y 2^1 - 1 = 1",
        "s2": "Paso 2: Hipótesis para n = k: 1+2+...+2^(k-1) = 2^k - 1",
        "s3": "Paso 3: Para k+1: (2^k - 1) + 2^k = 2*(2^k) - 1 = 2^(k+1) - 1",
        "dis": ["Caso base erróneo: 2^0 = 0", "Sumar 2^(k+1) en lugar de 2^k", "Afirmar 2^k + 2^k = 4^k", "Multiplicar por 2 sin sumar términos", "Reducir erróneamente 2^(k+1)-1 = 2^k"]
    },
    {
        "prop": "Suma de potencias de 3: 1 + 3 + 3^2 + ... + 3^(n-1) = (3^n - 1)/2",
        "s1": "Paso 1: Caso base n = 1: 3^0 = 1 y (3^1 - 1)/2 = 1",
        "s2": "Paso 2: Hipótesis para n = k: sum(3^i) = (3^k - 1)/2",
        "s3": "Paso 3: Para k+1: (3^k - 1)/2 + 3^k = (3*3^k - 1)/2 = (3^(k+1) - 1)/2",
        "dis": ["Caso base: 3^0 = 3", "Sumar 3^(k+1) antes de tiempo", "Afirmar que (3^k - 1)/2 + 3^k = (3^k + 3^k)/2", "Dividir entre 3 en vez de sumar", "Factorizar 3^k como 3*k"]
    }
]

facil_data = []
for i in range(30):
    tpl = facil_templates[i % len(facil_templates)]
    facil_data.append({
        "id": f"FACIL-{i+1:02d}",
        "hypothesis": f"Hipótesis #{i+1}: Probar que {tpl['prop']}",
        "description": "Pilota la nave y destruye los asteroides que contienen los pasos lógicos en el orden exacto:",
        "steps": [tpl["s1"], tpl["s2"], tpl["s3"]],
        "distractors": tpl["dis"] + [
            "Falacia de afirmación del consecuente",
            "Anulación por división entre cero",
            "Contraejemplo espurio en los números reales"
        ]
    })

# ----------------- NORMAL (4 Pasos) -----------------
normal_templates = [
    {
        "prop": "Suma de cuadrados: 1^2 + 2^2 + ... + n^2 = n(n+1)(2n+1)/6",
        "s1": "Paso 1: Probar caso base n = 1: 1^2 = 1*(2)*(3)/6 = 1",
        "s2": "Paso 2: Establecer hipótesis para n = k: 1^2+...+k^2 = k(k+1)(2k+1)/6",
        "s3": "Paso 3: Sumar (k+1)^2 a la hipótesis: k(k+1)(2k+1)/6 + (k+1)^2",
        "s4": "Paso 4: Factorizar término (k+1) y obtener (k+1)(k+2)(2k+3)/6",
        "dis": ["Caso base falso: 1^2 = 1*2*3 = 6", "Sumar k^2 en vez de (k+1)^2 en el paso 3", "Multiplicar denominadores por 6^2", "Afirmar que (k+1)(2k+1) = 2k^2 + 1", "Concluir sin factorizar que se cumple para todo n"]
    },
    {
        "prop": "Divisibilidad por 4: 5^n - 1 es divisible por 4 para todo n >= 1",
        "s1": "Paso 1: Evaluar caso base n = 1: 5^1 - 1 = 4, que es múltiplo de 4",
        "s2": "Paso 2: Hipótesis de inducción: 5^k - 1 = 4m para algún entero m",
        "s3": "Paso 3: Para n = k+1: 5^(k+1) - 1 = 5*(5^k) - 1 = 5*(4m + 1) - 1",
        "s4": "Paso 4: Simplificar: 20m + 4 = 4(5m + 1), que es divisible por 4",
        "dis": ["Evaluar caso base en n=0 y afirmar que 5^0 - 1 = 4", "Desarrollar 5^(k+1) como 5^k + 5", "Restar 4m en lugar de sustituir 5^k", "Afirmar que 5^n siempre termina en 0", "Sustituir k por m arbitrariamente"]
    },
    {
        "prop": "Desigualdad de Bernoulli: (1 + x)^n >= 1 + nx para x > -1 y n >= 1",
        "s1": "Paso 1: Comprobar base n = 1: (1 + x)^1 = 1 + 1*x (Igualdad se cumple)",
        "s2": "Paso 2: Hipótesis inductiva: Asumir que (1 + x)^k >= 1 + kx",
        "s3": "Paso 3: Multiplicar por (1 + x): (1 + x)^(k+1) >= (1 + kx)(1 + x)",
        "s4": "Paso 4: Desarrollar: 1 + (k+1)x + k*x^2 >= 1 + (k+1)x pues k*x^2 >= 0",
        "dis": ["Multiplicar por negativo e invertir sentido indebidamente", "Asumir que x^2 < 0 para números reales", "Caso base con x = -2 fuera de dominio", "Descartar el término lineal en vez del cuadrático", "Afirmar que (1+x)^k = 1 + x^k"]
    },
    {
        "prop": "Suma de cubos: 1^3 + 2^3 + ... + n^3 = (n(n+1)/2)^2",
        "s1": "Paso 1: Verificar caso base n = 1: 1^3 = 1 y (1*2/2)^2 = 1^2 = 1",
        "s2": "Paso 2: Plantear hipótesis para n = k: 1^3+...+k^3 = [k(k+1)/2]^2",
        "s3": "Paso 3: Sumar (k+1)^3: [k(k+1)/2]^2 + (k+1)^3 = (k+1)^2 * [k^2/4 + k + 1]",
        "s4": "Paso 4: Simplificar corchete a (k+2)^2/4 dando [(k+1)(k+2)/2]^2",
        "dis": ["Elevar al cubo el caso base obteniendo 1 = 3", "Sumar (k+1)^2 en lugar de (k+1)^3", "Distribuir el cuadrado como (k^2 + (k+1)^2)/4", "Olvidar el denominador 4 en la factorización", "Afirmar que la suma de cubos diverge"]
    },
    {
        "prop": "Divisibilidad por 6: n(n+1)(n+2) es múltiplo de 6 para todo n >= 1",
        "s1": "Paso 1: Caso base n = 1: 1*(2)*(3) = 6, el cual es divisible por 6",
        "s2": "Paso 2: Hipótesis: k(k+1)(k+2) = 6m para algún entero m",
        "s3": "Paso 3: Para k+1: (k+1)(k+2)(k+3) = k(k+1)(k+2) + 3(k+1)(k+2)",
        "s4": "Paso 4: Como 3(k+1)(k+2) tiene producto de dos consecutivos, es múltiplo de 6",
        "dis": ["Caso base: 1*2*3 = 5 (error aritmético)", "Desarrollar como k^3 + 3k^2 + 2k sin relacionar con la hipótesis", "Afirmar que dos números consecutivos no pueden ser pares", "Dividir entre k+1 sin verificar si es cero", "Sustituir k = k+2 directamente"]
    }
]

normal_data = []
for i in range(30):
    tpl = normal_templates[i % len(normal_templates)]
    normal_data.append({
        "id": f"NORMAL-{i+1:02d}",
        "hypothesis": f"Hipótesis #{i+1}: Probar que {tpl['prop']}",
        "description": "Completa los 4 pasos ordenados de la demostración inductiva destruyendo los asteroides correspondientes:",
        "steps": [tpl["s1"], tpl["s2"], tpl["s3"], tpl["s4"]],
        "distractors": tpl["dis"] + [
            "Paso fuera de secuencia temporal",
            "Violación de la regla de inferencia modus ponens",
            "Generalización precipitada sin paso inductivo"
        ]
    })

# ----------------- INGENIERO (5 Pasos) -----------------
ingeniero_templates = [
    {
        "prop": "Suma de fracciones telecópicas: 1/(1*2) + 1/(2*3) + ... + 1/(n(n+1)) = n/(n+1)",
        "s1": "Paso 1: Probar caso base n = 1: 1/(1*2) = 1/2 y 1/(1+1) = 1/2",
        "s2": "Paso 2: Asumir hipótesis inductiva para n = k: sum(1/(i(i+1))) = k/(k+1)",
        "s3": "Paso 3: Sumar término k+1: k/(k+1) + 1/((k+1)(k+2))",
        "s4": "Paso 4: Denominador común (k+1)(k+2): [k(k+2) + 1]/((k+1)(k+2)) = (k+1)^2/((k+1)(k+2))",
        "s5": "Paso 5: Cancelar factor (k+1): (k+1)/(k+2) completando la inducción",
        "dis": ["Caso base falso: 1/2 = 1/3", "Sumar 1/(k(k+1)) en lugar del término k+1", "Sumar numeradores directamente sin común denominador", "Afirmar que k(k+2)+1 = k^2 + 2", "Invertir la fracción resultante a (k+2)/(k+1)"]
    },
    {
        "prop": "Divisibilidad: 7^n - 1 es divisible por 6 para todo entero n >= 1",
        "s1": "Paso 1: Probar caso base n = 1: 7^1 - 1 = 6, divisible por 6 (6 = 6*1)",
        "s2": "Paso 2: Formular hipótesis para n = k: 7^k - 1 = 6m con m entero",
        "s3": "Paso 3: Analizar n = k+1: 7^(k+1) - 1 = 7*(7^k) - 1",
        "s4": "Paso 4: Descomponer 7 como (6 + 1): (6 + 1)*7^k - 1 = 6*7^k + (7^k - 1)",
        "s5": "Paso 5: Sustituir hipótesis: 6*7^k + 6m = 6(7^k + m), confirmando divisibilidad",
        "dis": ["Evaluar caso base: 7^1 - 1 = 7 (error)", "Descomponer 7 como 5 + 2", "Afirmar que 7^(k+1) - 1 = (7^k - 1)^2", "Dividir entre 7 a ambos miembros", "Concluir que 7^n siempre es un número par"]
    },
    {
        "prop": "Desigualdad de potencias: 2^n >= n^2 para todo n >= 4",
        "s1": "Paso 1: Verificar caso base en n = 4: 2^4 = 16 y 4^2 = 16 (16 >= 16 Verdadero)",
        "s2": "Paso 2: Hipótesis inductiva: 2^k >= k^2 para k >= 4",
        "s3": "Paso 3: Evaluar k+1 en potencia: 2^(k+1) = 2 * 2^k >= 2*k^2 = k^2 + k^2",
        "s4": "Paso 4: Demostrar lema: Para k >= 4 se cumple k^2 >= 2k + 1",
        "s5": "Paso 5: Sustituir lema: k^2 + k^2 >= k^2 + 2k + 1 = (k+1)^2 (QED)",
        "dis": ["Tomar como caso base n = 1 donde la desigualdad falla (2 < 4)", "Afirmar que 2k^2 = (2k)^2", "Restar k^2 de ambos lados sin conservar la desigualdad", "Usar el lema para k < 2", "Declarar que la hipótesis es falsa para todo n"]
    },
    {
        "prop": "Propiedad de conjuntos: Un conjunto de n elementos tiene 2^n subconjuntos",
        "s1": "Paso 1: Probar caso base n = 0: Conjunto vacío tiene 1 subconjunto (2^0 = 1)",
        "s2": "Paso 2: Hipótesis de inducción: Todo conjunto con k elementos tiene 2^k subconjuntos",
        "s3": "Paso 3: Considerar un conjunto S con k+1 elementos: S = S_k union {x}",
        "s4": "Paso 4: Clasificar subconjuntos: Aquellos sin x (2^k) y aquellos con x (otros 2^k)",
        "s5": "Paso 5: Totalizar: 2^k + 2^k = 2 * 2^k = 2^(k+1) subconjuntos",
        "dis": ["Caso base falso: conjunto vacío tiene 0 subconjuntos", "Multiplicar 2^k * 2^k obteniendo 2^(2k)", "Ignorar los subconjuntos que contienen el elemento x", "Afirmar que el conjunto potencia es finito sólo para n=0", "Restar 1 por el conjunto vacío en el conteo total"]
    },
    {
        "prop": "Fórmula de sumatoria aritmética general: sum(a + (i-1)d) = n/2 * (2a + (n-1)d)",
        "s1": "Paso 1: Caso base n = 1: Término inicial a y 1/2*(2a + 0*d) = a",
        "s2": "Paso 2: Hipótesis inductiva para n = k: S_k = k/2 * [2a + (k-1)d]",
        "s3": "Paso 3: Para n = k+1: Sumar término (k+1)-ésimo: S_k + [a + kd]",
        "s4": "Paso 4: Agrupar con común denominador 2: [2ka + k(k-1)d + 2a + 2kd] / 2",
        "s5": "Paso 5: Factorizar en [(k+1)(2a + kd)] / 2, que coincide con la fórmula evaluada en k+1",
        "dis": ["Caso base: evaluar n=1 da 2a+d", "Sumar d en lugar de (a + kd)", "Desarrollar k(k-1)d como k^2*d", "Factorizar erróneamente omitiendo el factor a", "Cambiar el signo de la diferencia común d"]
    }
]

ingeniero_data = []
for i in range(30):
    tpl = ingeniero_templates[i % len(ingeniero_templates)]
    ingeniero_data.append({
        "id": f"INGENIERO-{i+1:02d}",
        "hypothesis": f"Hipótesis #{i+1}: Probar que {tpl['prop']}",
        "description": "Demuestra la proposición ejecutando rigurosamente la secuencia de los 5 pasos formales de inducción:",
        "steps": [tpl["s1"], tpl["s2"], tpl["s3"], tpl["s4"], tpl["s5"]],
        "distractors": tpl["dis"] + [
            "Paso lógico desfasado o invertido",
            "Anulación de hipótesis por premisa contradictoria",
            "Petición de principio (circularidad deductiva)"
        ]
    })

path_base = r"C:\MorelosoftInternational\pixeling\scenes\minigames\logica\cinturon_hipotesis\data"

with open(f"{path_base}\\questions_facil.json", "w", encoding="utf-8") as f:
    json.dump(facil_data, f, ensure_ascii=False, indent=2)

with open(f"{path_base}\\questions_normal.json", "w", encoding="utf-8") as f:
    json.dump(normal_data, f, ensure_ascii=False, indent=2)

with open(f"{path_base}\\questions_ingeniero.json", "w", encoding="utf-8") as f:
    json.dump(ingeniero_data, f, ensure_ascii=False, indent=2)

print("Archivos JSON generados exitosamente con 30 items cada uno.")
