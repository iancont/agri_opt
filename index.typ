// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let unescape-eval(str) = {
  return eval(str.replace("\\", ""))
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [Optimización de Portafolio Agrícola: Una Alternativa para la Mitigación de Riesgos en la República Dominicana],
  authors: (
    ( name: [Ian Contreras],
      affiliation: [],
      email: [] ),
    ( name: [Elvis Lagrange],
      affiliation: [],
      email: [] ),
    ),
  date: [12 de enero de 2025],
  lang: "es",
  sectionnumbering: "1.1.a",
  toc: true,
  toc_title: [Tabla de contenidos],
  toc_depth: 3,
  cols: 1,
  doc,
)

#pagebreak()
= Introducción
<introducción>
El sector agrícola en la República Dominicana juega un papel fundamental en el desarrollo económico nacional, representando el $3 %$ del Producto Interno Bruto y generando empleo para aproximadamente 361,063 personas. Las exportaciones agrícolas constituyen el $6.4 %$ de las exportaciones totales, evidenciando la importancia estratégica del sector en el comercio internacional. Sin embargo, un análisis detallado revela ineficiencias estructurales y fallas de mercado significativas que restringen su potencial de desarrollo.

Una preocupación primordial es la estructura poco concentrada de la propiedad de la tierra, donde el $77 %$ de los productores operan parcelas menores a $4.5$ hectáreas, mientras que el $10 %$ de los grandes productores controlan el $61 %$ de la tierra agrícola. Esta distribución asimétrica genera barreras sustanciales para que los pequeños productores alcancen economías de escala y accedan a instrumentos sofisticados de gestión de riesgos. La situación se agrava por una infraestructura rural deficiente, incluyendo sistemas de riego inadecuados, instalaciones de almacenamiento limitadas y redes de transporte subdesarrolladas, lo que incrementa significativamente los costos de producción y transacción.

El sector agrícola dominicano enfrenta riesgos multidimensionales que impactan severamente su competitividad internacional. Los riesgos climáticos, particularmente huracanes, sequías e inundaciones, generan pérdidas sustanciales en la producción. Los riesgos de mercado, derivados de la volatilidad de precios y posiciones desfavorables de negociación con intermediarios en la cadena de valor, crean presiones económicas adicionales. La situación es particularmente aguda para productos con curvas de oferta inelástica y ciclos de cosecha anual concentrados, como el arroz, donde los productores tienen capacidad limitada para responder a las señales del mercado.

La exposición a riesgos biológicos, incluyendo plagas y enfermedades, combinada con el acceso limitado a instrumentos financieros como seguros agrícolas, contratos futuros y mecanismos de cobertura, crea una situación de alta vulnerabilidad. Los pequeños productores, que constituyen la mayoría, carecen de las economías de escala necesarias para costear estrategias tradicionales de mitigación de riesgos. Los altos costos de transacción e ineficiencias operativas hacen que las primas de seguros sean prohibitivamente caras en relación con los costos de producción para la mayoría de los agricultores locales.

La ausencia de herramientas efectivas de gestión de riesgos en la agricultura dominicana refleja fallas estructurales de mercado más profundas. Los instrumentos financieros tradicionales resultan inadecuados debido a varios factores: la pequeña extensión promedio de las explotaciones agrícolas, los bajos niveles de productividad y los altos costos de transacción hacen que los esquemas convencionales de seguros sean económicamente inviables para la mayoría de los productores. Esta situación se ve agravada por la naturaleza informal de muchas operaciones agrícolas y la limitada educación financiera, que crean barreras adicionales para acceder a herramientas sofisticadas de gestión de riesgos.

En la práctica, los agricultores dominicanos carecen de estrategias efectivas para la mitigación de riesgos. Aunque la diversificación de cultivos podría teóricamente ayudar a gestionar el riesgo, la mayoría de los productores no tienen suficiente extensión de tierra para implementar estrategias de diversificación efectivas. Aquellos que intentan diversificar a menudo lo hacen de manera subóptima, típicamente basando sus decisiones en los rendimientos del año anterior en lugar de un análisis comprensivo de riesgo-retorno. Este enfoque no considera las condiciones cambiantes del mercado ni la evolución del panorama de riesgos.

Ante esta problemática, la presente investigación propone desarrollar una metodología de optimización ajustada por riesgo para la selección de cultivos agrícolas que maximice los beneficios económicos de los productores. Basándonos en el trabajo de @miao_optimization_2023, quien aplicó la teoría de portafolio a la asignación de recursos agrícolas, proponemos un marco que maximiza los rendimientos ajustados por riesgo considerando las restricciones específicas que enfrentan los agricultores dominicanos. La innovación clave de nuestra metodología radica en su enfoque agnóstico a las fallas del mercado, proporcionando una herramienta práctica para optimizar la selección de cultivos dentro de las restricciones existentes, sin requerir cambios institucionales o nuevos instrumentos financieros.

Esta metodología representa un mecanismo de tecnificación implícita que permite mejorar la productividad de la cosecha sin necesidad de aumentar significativamente el capital inicial. A través de la optimización sistemática de la selección de cultivos, los agricultores pueden maximizar sus beneficios económicos mientras gestionan efectivamente los riesgos inherentes a la producción agrícola.

Un aspecto fundamental de esta metodología es su capacidad para maximizar el beneficio económico ajustado por riesgo. A diferencia de enfoques tradicionales que requieren inversiones sustanciales en tecnificación o modernización agrícola,esta optimización actúa como un mecanismo de tecnificación implícita, ya que mejora la productividad global de la explotación agrícola a través de una asignación más eficiente de los recursos existentes, sin requerir inversiones significativas de capital inicial. Al identificar la combinación óptima de cultivos que maximiza el rendimiento para un nivel dado de riesgo, los agricultores pueden mejorar sus resultados económicos utilizando los mismos recursos productivos, pero de manera más estratégica y eficiente. Este enfoque es particularmente valioso en el contexto dominicano, donde las limitaciones de capital y acceso al financiamiento constituyen barreras significativas para la modernización agrícola tradicional.

El objetivo principal de esta investigación es desarrollar y validar una metodología de optimización de portafolio que permita a los productores agrícolas dominicanos maximizar los rendimientos ajustados por riesgo a través de una selección óptima de cultivos. Buscamos formular un modelo matemático que capture los compromisos entre riesgo y rendimiento en la producción agrícola, considerando las condiciones y restricciones del mercado local. La metodología incorporará restricciones de capacidad por cultivo o categoría de cultivos, extensiones mínimas de cosecha y otras restricciones específicas del productor. Este enfoque pretende proporcionar una solución pragmática a los desafíos de gestión de riesgos que enfrenta la agricultura dominicana, ofreciendo una metodología que puede implementarse independientemente del tamaño de la finca o el acceso a instrumentos financieros, contribuyendo así a mejorar la sostenibilidad económica del sector agrícola dominicanos estructurales y fallas de mercado significativas que restringen su potencial de desarrollo.

#pagebreak()
= Metodología
<metodología>
La presente sección desarrolla la fundamentación teórica y práctica del modelo de optimización de carteras agrícolas. Primero, presenta la adaptación de la Teoría Moderna de Portafolios de Markowitz al contexto agrícola, explicando cómo esta transformación permite optimizar la asignación de recursos entre cultivos. Posteriormente, detalla la construcción de una matriz técnica para el cálculo de rentabilidades históricas por cultivo, utilizando datos del Ministerio de Agricultura de la República Dominicana, que servirá como insumo fundamental para la estimación del modelo.

== Teoría de portafolio de Markowitz aplicada a la agricultura
<teoría-de-portafolio-de-markowitz-aplicada-a-la-agricultura>
Como agricultor, usted enfrenta anualmente una decisión crucial: determinar qué cultivar hoy para cosechar en el próximo ciclo productivo. Esta decisión implica establecer qué proporción de su finca destinará a cada cultivo con el objetivo de maximizar sus beneficios futuros. Si bien tradicionalmente los agricultores han basado estas decisiones en su experiencia previa, preferencias personales o replicando los cultivos más rentables de temporadas anteriores, este enfoque intuitivo, aunque comprensible, presenta limitaciones significativas al no considerar sistemáticamente dos factores fundamentales: el riesgo inherente a cada cultivo y las interrelaciones entre los rendimientos de diferentes productos agrícolas.

En el ámbito de los mercados financieros, los inversores enfrentaron históricamente un dilema similar al tratar de optimizar sus carteras de inversión. En 1952, Harry Markowitz revolucionó la teoría financiera al desarrollar la Teoría Moderna de Portafolios (MPT), trabajo que le mereció el Premio Nobel de Economía en 1990. Su contribución fundamental radica en establecer que tanto inversores como productores agrícolas son adversos al riesgo y buscan optimizar la relación entre el beneficio esperado y el riesgo asociado a sus decisiones.

Esta teoría puede adaptarse elegantemente al contexto agrícola considerando cada cultivo como un "activo" dentro del "portafolio agrícola" que representa nuestra finca. Así, la decisión sobre qué proporción de tierra destinar a cada cultivo se transforma en un problema de optimización matemática donde buscamos maximizar los beneficios esperados para el próximo ciclo productivo. En este problema, nuestras variables de control son las proporciones de tierra a destinar a cada cultivo, decisión que debe tomarse considerando dos restricciones fundamentales: la capacidad limitada de nuestra finca (medida en tareas) y el riesgo inherente a cada combinación de cultivos. Esta última restricción es particularmente relevante dado que, como agricultores, enfrentamos múltiples fuentes de incertidumbre: riesgos biológicos, climáticos, de mercado, financieros y de disponibilidad de insumos.

La formalización matemática de este proceso de decisión, que se toma al inicio del período t y se mantiene hasta su finalización, considera tres elementos fundamentales: la rentabilidad media esperada del conjunto de cultivos, la cuantificación del riesgo mediante la varianza de la rentabilidad, y la optimización de la función objetivo sujeta a nuestras restricciones de capacidad y riesgo. Este enfoque nos permite transformar la intuición y experiencia del agricultor en un marco analítico riguroso para la toma de decisiones.

Formalmente, consideramos que cada cultivo $i$ recibe una fracción $x_i$ de los recursos disponibles, principalmente tierra, agua y mano de obra. Una restricción fundamental es que la suma de estas fracciones debe ser igual a uno, es decir, $sum_(i = 1)^n x_i = 1$, lo que garantiza la utilización completa de las tareas de nuestra finca.

Bajo estas condiciones, la rentabilidad esperada del portafolio agrícola se fundamenta en la la suma de los rendimientos esperados de los cultivos multiplicados por el peso relativo que tienen en la plantación la rentabilidad esperada del portafolio agrícola se expresa matemáticamente como:

$ R = sum_(i = 1)^n x_i r_i $

donde $R$ representa el retorno esperado total del portafolio agrícola y $r_i$ corresponde al rendimiento esperado individual del cultivo $i$. Esta fórmula nos indica que el retorno total esperado es un promedio ponderado de los rendimientos esperados de cada cultivo, donde las pes recibidos por el productor (expresados en RD\$/kg); Los costos anuales de producción por tarea; nEl ciclo de cosecha específico de cada cultivo.

La asunción de normalidad en la distribución de los rendimientos históricos nos permite utilizar la media aritmética como un estimador insesgado del rendimiento esperado. Esta suposición, aunque simplificadora, ha demostrado ser suficientemente robusta para la mayoría de las aplicaciones prácticas en la planificación agrícola. Sin embargo, es importante señalar que en casos donde los rendimientos históricos muestran patrones claramente no normales, pueden ser necesarios métodos más sofisticados de estimación.

En el contexto de la producción agrícola, el riesgo representa la incertidumbre asociada a los retornos futuros de nuestra inversión. Para cuantificar este riesgo, utilizamos la varianza del portafolio ($phi.alt_k (w)$), una medida estadística que nos permite evaluar la volatilidad esperada de los retornos de nuestra selección de cultivos. Matemáticamente, esta varianza se expresa como:

$ phi.alt_k (w) = sum_(i = 1)^n sum_(j = 1)^n x_i x_j sigma_(i j) $

Esta fórmula, aparentemente compleja, captura elementos fundamentales del riesgo agrícola. Las variables $x_i$ y $x_j$ representan las proporciones de recursos (principalmente tierra) destinadas a los cultivos i y j respectivamente. El término $sigma_(i j)$ representa la covarianza entre los retornos de estos cultivos, un concepto crucial que merece especial atención.

La covarianza $sigma_(i j)$ mide cómo los rendimientos de dos cultivos se mueven conjuntamente a lo largo del tiempo. Matemáticamente, se calcula como:

$ sigma_(i j) = E [(r_i - E (r_i)) (r_j - E (r_j))] = E (r_i r_j) - E (r_i) E (r_j) $

Para entender este concepto en términos prácticos, consideremos algunos ejemplos agrícolas concretos. Imaginemos dos cultivos: arroz y maíz. Si ambos cultivos tienden a tener buenos rendimientos en años lluviosos y malos rendimientos en años secos, mostrarán una covarianza positiva. Esto significa que sus retornos tienden a moverse en la misma dirección, lo cual podría aumentar nuestro riesgo total si las condiciones climáticas son desfavorables.

Por otro lado, consideremos un agricultor que cultiva tanto productos de ciclo corto (como hortalizas) como de ciclo largo (como frutales perennes). Estos cultivos podrían mostrar una covarianza negativa, ya que factores que afectan negativamente a uno podrían beneficiar al otro. Por ejemplo, un período de lluvias intensas podría dañar las hortalizas pero beneficiar a los frutales, o viceversa.

La importancia de la covarianza en la gestión del riesgo agrícola no puede subestimarse. Cuando la covarianza entre dos cultivos es positiva y alta, significa que ambos tienden a experimentar pérdidas simultáneas, lo cual podría ser catastrófico para el agricultor. En cambio, una covarianza negativa indica que cuando un cultivo experimenta pérdidas, el otro tiende a mostrar ganancias, proporcionando así un efecto de compensación natural que reduce el riesgo total del portafolio.

Este principio fundamenta la estrategia de diversificación en agricultura. Al seleccionar cultivos con covarianzas negativas o bajas entre sí, podemos construir un portafolio agrícola más resiliente. Por ejemplo, un agricultor podría combinar cultivos que responden diferentemente a las condiciones climáticas, tienen diferentes ciclos de producción, o sirven a diferentes mercados. Esta diversificación no solo reduce el riesgo total sino que también puede estabilizar los ingresos a lo largo del año.

La varianza total del portafolio ($phi.alt_k (w)$) integra todas estas covarianzas, ponderadas por las proporciones de recursos asignados a cada cultivo. Así, el riesgo total no es simplemente la suma de los riesgos individuales de cada cultivo, sino que depende crucialmente de cómo estos cultivos se relacionan entre sí. Este entendimiento nos permite diseñar estrategias de producción que no solo maximizan el retorno esperado sino que también minimizan nuestra exposición a riesgos sistemáticos en la agricultura.

La metodología planteada por Markowitz, al combinar los conceptos de la varianza total del portafolio ($V$) y la rentabilidad esperada($R$), permite determinar la proporción óptima de recursos(tareas) asignados a cada cultivo. Este lo logra al introducir el concepto del Sharpe Ratio. Expresándose matemáticamente como $(R (w) - r_f) \/ phi.alt_k (w)$, $r_f$ representa el costo de oportunidad de la tierra (como el ingreso por arrendamiento). Este ratio nos proporciona una medida crucial: cuánto retorno adicional obtenemos por cada unidad de riesgo asumido en nuestra selección de cultivos.Para ilustrar la intuición detrás de la métrica, consideremos el siguiente ejemplo: Aunque un cultivo pueda ofrecer una rentabilidad 1% superior en términos absolutos, si este conlleva un riesgo significativo de pérdida total de la inversión, mientras que la alternativa presenta un riesgo mínimo, la decisión óptima se vuelve evidente. La clave no radica simplemente en el potencial de ganancia, sino en la relación entre el retorno esperado y el riesgo de pérdida asociado. Es este coeficiente de retorno/riesgo, el cual es el objetivo de optimización de nuestra metodología, equilibrando la rentabilidad potencial con la volatilidad inherente a cada rubro. Por lo tanto, el problema de optimización se puede plantear como:

$  & max_w &  & frac(R (w) - r_f, phi.alt_k (w))\
 & upright("s.t.") &  & A w lt.eq B\
 &  &  & phi.alt_i (w) lt.eq c_i #h(0em) forall #h(0em) i #h(0em) in #h(0em) [1 , 13]\
 &  &  & R (w) gt.eq overline(mu) $

Donde:

+ $R (w)$ es la función de retorno, con los siguientes valores posibles:$mu w$: retorno aritmético.

+ $w$: es el vector de pesos del portafolio óptimo.

+ $mu$: es el vector de retornos esperados.

+ $Sigma$: es la matriz de covarianza de los retornos de los activos.

+ $r$: es la matriz de retornos de los activos.

+ $A w lt.eq B$: representa un conjunto de restricciones lineales.

+ $phi.alt_i (w)$: son $20$ medidas de riesgo disponibles. Las medidas de riesgo disponibles son varianza, semi-varianza, valor en riesgo (VaR), y otras medidas de riesgo a la baja. La manera de medir el riesgo tomara relevancia más adelante en la discusión.

Al resolver estos problemas de optimización, se obtienen asignaciones de cultivos que minimizan la volatilidad (varianza) para un determinado umbral de rentabilidad o, de manera equivalente, que maximizan los retornos sin sobrepasar el riesgo prefijado. En consecuencia, se estaría construyendo la "frontera eficiente", que representa todas de asignaciones de recursos a los distintos rubros agrícolas que brindan el mayor rendimiento esperado para cada nivel de riesgo o, de manera equivalente, el menor riesgo para un nivel de rendimiento específico.

Entre los portafolios que conforman la frontera eficiente, el denominado "portafolio óptimo" es aquel que maximiza el beneficio ajustado al riesgo y, por ende, equilibra de manera adecuada la rentabilidad y la volatilidad esperada. Esta herramienta resulta especialmente útil para los productores que buscan decisiones informadas y sostenibles en la asignación de sus recursos. En este punto, resulta relevante mostrar cómo se implementa este método en la práctica.

Los agricultores suelen adoptar un enfoque empírico al asignar recursos a sus distintos cultivos, basándose en su experiencia y en un análisis intuitivo de los cultivos que consideran más rentables. Esta heurística, aunque práctica en el corto plazo, presenta deficiencias estructurales. Para empezar, los rendimientos pasados no garantizan resultados futuros debido a factores climáticos, enfermedades o fluctuaciones del mercado, lo que genera alta incertidumbre en su capacidad predictiva. En contraste, la MPT incorpora la varianza y la covarianza de los rendimientos históricos para estimar la rentabilidad esperada ajustada al riesgo, permitiendo decisiones más robustas frente a incertidumbres futuras. Además, mientras la selección intuitiva de cultivos maximiza beneficios en el corto plazo, ignora los beneficios de la diversificación, que reduce el riesgo total y mejora la rentabilidad ajustada en el largo plazo.

La programación lineal (PL), aunque común en la optimización de recursos agrícolas, también presenta restricciones significativas. Asume una rentabilidad fija y determinista para cada cultivo, limitando su capacidad para modelar la incertidumbre inherente a la producción agrícola. Por el contrario, la MPT optimiza en función de la rentabilidad esperada ponderada por el riesgo, considerando también las interacciones entre cultivos a través de las covarianzas. Esto permite capitalizar los efectos diversificadores de combinar cultivos con baja o negativa correlación, algo que la PL no puede modelar. Además, la MPT proporciona un marco más flexible que permite adaptaciones dinámicas a condiciones cambiantes, mientras que la PL tiende a ofrecer soluciones rígidas y poco realistas, como la asignación completa de recursos a un solo cultivo.

Adoptar la MPT en la planificación agrícola implica un cambio paradigmático en cómo los agricultores asignan sus recursos. El modelo ofrece una herramienta analítica que trasciende la simple intuición y las restricciones lineales, al emplear datos históricos sobre rendimientos, precios y costos para maximizar la rentabilidad esperada ajustada por riesgo. Al identificar combinaciones de cultivos con baja correlación, la MPT reduce la volatilidad del portafolio, proporcionando estabilidad en los ingresos y permitiendo ajustes dinámicos basados en las condiciones del mercado y las variaciones climáticas.

== Matriz técnica para el calculo de la rentabilidad por rubro Agrícola.
<matriz-técnica-para-el-calculo-de-la-rentabilidad-por-rubro-agrícola.>
El proceso de optimización requiere como insumo un histórico del retorno anual por cultivo para poder estimar los valores de retorno esperado y riesgo. Debido a la insuficiencia de información, tuvimos que aproximar $r_i$ de cada cultivo utilizando una matriz técnica. Dicha matriz fue alimentada con datos que fueron obtenidos del Ministerio de Agricultura de la República Dominicana.

EL cálculo de los rendimientos agrícolas se realiza mediante una fórmula que integra varios componentes críticos: la productividad promedio anual (medida en kilogramos por tarea, kg/tarea), los precios promedio anuales al productor (en RD\$/kg), los costos anuales de producción por tarea y el ciclo de cosecha de cada cultivo. La fórmula utilizada es la siguiente:

$ frac(upright("Productividad") dot.op upright("Precio") - upright("costo"), upright("costo")) dot.op (upright("ciclo")) $

El numerador de la fórmula, que considera la diferencia entre la productividad multiplicada por el precio y los costos de producción, representa los beneficios netos generados por cada cultivo en un período específico. El denominador, que utiliza los costos totales, permite obtener una medida estandarizada de rendimiento relativo. Se utiliza costos totales como una variable proxy de lo que seria el capital inicial de inversion, bajo el supuesto que el capital de dichos costos se tiene que invertir en el tiempo de cultivo. Este supuesto se hizo por insuficiencia de dato en la inversion inicial.

La expresión de rentabilidad en términos relativos al capital inicial representa un aspecto fundamental en el análisis de inversiones agrícolas, ya que establece una independencia escalar. Esta característica permite que el análisis mantenga su validez sin importar el tamaño de la unidad productiva. Al normalizar los rendimientos con respecto al capital invertido, los resultados son agnósticos a la extension de tierra, facilitando comparaciones significativas entre diferentes cultivos y regiones.

El componente cíclico en la fórmula de rendimientos agrícolas cumple una función fundamental de estandarización temporal. Este multiplicador ajusta los rendimientos según la frecuencia potencial de cosecha anual, permitiendo una comparación equitativa entre cultivos de diferentes duraciones. Por ejemplo, un cultivo trimestral tendría un multiplicador de 4, reflejando su potencial de producción cuatro veces al año. Esta consideración es crucial por dos razones principales: permite comparar adecuadamente cultivos de diferentes duraciones y reconoce el valor del tiempo en términos de rotación de capital. Sin embargo, es importante notar que representa un máximo teórico, sujeto a restricciones prácticas como condiciones climáticas y recursos disponibles.

El resultado final es la rentabilidad relativa anual para cada cultivo de nuestro universo de trabajo, durante el período 2002 hasta 2023. La serie temporal resultante representa una medida estandarizada del desempeño financiero de cada cultivo, expresada como un rendimiento anualizado sobre el capital invertido. Esta métrica permite una comparación directa entre cultivos con diferentes características agronómicas.

El rendimiento esperado de cada cultivo ($r_i$) merece especial atención en su cálculo. Si bien existen diversos métodos para su estimación, el más utilizado es el promedio aritmético de los rendimientos históricos, asumiendo que estos siguen una distribución normal. Este rendimiento se calcula considerando cuatro componentes fundamentales: La productividad física promedio anual del cultivo, medida en kilogramos por tarea (kg/tarea); Los precios promedio anual

#pagebreak()
= Datos
<datos>
La optimización de portafolios en esta investigación se basa en el cálculo de rendimientos agrícolas, tomando como activos 12 cultivos clave: arroz, maíz, papa blanca, batata, yautía blanca, ñame, berenjena criolla, auyama, aguacate, guineo verde y plátano. La elección de estos cultivos responde a dos factores principales. En primer lugar, se seleccionaron debido a su alta disponibilidad, facilitando así el análisis de rendimientos y costos de producción. En segundo lugar, estos rubros tienen una gran relevancia en la dieta dominicana, lo que asegura que los resultados del modelo sean representativos y aplicables para los agricultores que buscan maximizar su rentabilidad en contextos locales.

== Análisis de la estadística descriptiva
<análisis-de-la-estadística-descriptiva>
#block[
#table(
  columns: 6,
  align: (left,auto,auto,auto,auto,auto,),
  table.header([Estadísticas Descriptivas por Rubro (En Porcentajes)], [], [], [], [], [],),
  table.hline(),
  [Rubro], [Media (%)], [Mediana (%)], [Desviación Estándar (%)], [Mínimo (%)], [Máximo (%)],
  [Auyama], [559.67%], [523.76%], [318.73%], [0%], [1186.51%],
  [Aguacate], [159.58%], [59.83%], [354.78%], [-195.12%], [1187.04%],
  [Papa], [142.92%], [157.05%], [118.92%], [-98.91%], [331.95%],
  [Yautía], [112.41%], [77.95%], [114.34%], [0%], [556.21%],
  [Yuca], [50.64%], [34.77%], [65.06%], [-43.96%], [185.35%],
  [Ñame], [35.65%], [36.93%], [25.58%], [-17.55%], [73.19%],
  [Batata], [29.94%], [13.94%], [70.77%], [-72.18%], [255.74%],
  [Plátano], [-6.55%], [0%], [28.36%], [-69.69%], [30.17%],
  [Guineo], [-23.27%], [-35.76%], [28.41%], [-59.39%], [32.57%],
  [Maíz], [-78.6%], [-82.19%], [51.97%], [-172.5%], [0%],
  [Berenjena], [-80.4%], [-78.52%], [49.94%], [-166.3%], [0%],
  [Arroz], [-108.25%], [-122.29%], [45.57%], [-158.82%], [0%],
)
Estadísticas descriptivas de la rentabilidad por rubro

]
El análisis de las estadísticas descriptivas del sector agrícola dominicano revela importantes patrones en la rentabilidad y volatilidad de diversos cultivos, identificando tres grupos principales según su desempeño financiero. Los cultivos de alta rentabilidad como la auyama y el aguacate muestran retornos sobresalientes de 559.67% y 159.58% respectivamente, aunque acompañados de una elevada volatilidad con desviaciones estándar de 318.73% y 354.78%. En contraste, cultivos tradicionales como la papa, la yautía y la yuca presentan un perfil más moderado, con rentabilidades de 142.92%, 112.41% y 50.64% respectivamente, mostrando mayor estabilidad en sus retornos.

El tercer grupo incluye cultivos que registran pérdidas consistentes, como el arroz, el maíz y la berenjena, con rentabilidades negativas de -108.25%, -78.6% y -80.4%, mientras que el ñame y la batata mantienen rentabilidades modestas pero positivas de 35.65% y 29.94%. Estos resultados, aunque sujetos a posibles limitaciones en la calidad de los datos, proporcionan una base sólida para comprender la dinámica económica del sector agrícola dominicano y sus distintos niveles de rendimiento financiero.

== Análisis exploratorio de los rendimientos de los rubros agrícolas
<análisis-exploratorio-de-los-rendimientos-de-los-rubros-agrícolas>
El análisis de la evolución de la rentabilidad de los rubros agrícolas, más allá de evaluar las ganancias potenciales, nos permite comprender de manera implícita los riesgos asociados a los costos, precios y mercados. Esto es esencial para identificar las dinámicas económicas subyacentes que afectan la sostenibilidad de cada cultivo. Por ejemplo, en rubros como el aguacate y la auyama, su alta rentabilidad evidencia oportunidades económicas, pero al mismo tiempo resalta riesgos de mercado asociados a la volatilidad de los precios internacionales y a los costos de exportación (@fig-costs_by_crop). Esto indica que, aunque hay grandes posibilidades de ingresos, los productores están expuestos a fluctuaciones que pueden reducir drásticamente sus márgenes en años desfavorables.

Por otro lado, cultivos como el arroz, que mantienen rentabilidades negativas, reflejan riesgos estructurales importantes. Estos riesgos no solo están relacionados con la competitividad del mercado, sino también con los costos de producción y los insumos, que en este caso parecen superar consistentemente los ingresos generados (@fig-price_by_crop). Este desequilibrio muestra cómo los riesgos financieros y de insumo impactan directamente en la rentabilidad.

Rubros con rentabilidades más estables, como la papa y la yautía, indican una menor exposición a riesgos de mercado, probablemente debido a su demanda constante en el consumo local. Sin embargo, los costos crecientes, como se observa en las gráficas (@fig-profit_by_crop), representan un riesgo financiero latente que podría afectar negativamente su rentabilidad a largo plazo si no se mejoran los procesos productivos.

En cultivos como el maíz y la berenjena, la alta volatilidad de la rentabilidad pone en evidencia riesgos combinados tanto del mercado (por fluctuaciones en la demanda o precios) como de insumos, dado que estos cultivos son más sensibles a factores climáticos y requieren inversiones variables en fertilizantes y mano de obra. Esto refuerza la idea de que la rentabilidad, al ser un indicador multifacético, es clave para captar la interacción entre los riesgos de insumos, financieros y de mercado.

Tras analizar los rendimientos, es evidente que las volatilidades en los precios han tenido implicaciones importantes en la dinámica de la rentabilidad para los agricultores dominicanos. La variabilidad en los precios de los insumos y productos agrícolas afecta directamente la capacidad de los productores para planificar su producción, ya que estas fluctuaciones generan incertidumbre en la previsión de ingresos y costos. Según datos disponibles, esta incertidumbre suele desincentivar la inversión en potencial de ganancias y aumenta su exposición a riesgos específicos.

La volatilidad de los precios de los productos agrícolas puede traducirse en márgenes de ganancia más reducidos para los agricultores, especialmente en aquellos períodos en los que los costos de insumos, como fertilizantes o semillas, aumentan significativamente. Cuando los precios de los productos no reflejan de manera proporcional estos incrementos en los costos, los productores enfrentan una reducción en sus ingresos netos, lo que compromete la sostenibilidad de sus operaciones. Además, en ausencia de herramientas adecuadas como seguros agropecuarios, los agricultores más afectados por estas fluctuaciones pueden quedar atrapados en ciclos de endeudamiento, limitando aún más su capacidad de inversión y crecimiento.

== Análisis de la matriz de correlación de la rentabilidad de los rubros
<análisis-de-la-matriz-de-correlación-de-la-rentabilidad-de-los-rubros>
#figure([
#box(image("notebooks/opt/cluster.png"))
], caption: figure.caption(
position: bottom, 
[
Agrupamiento jerárquico de los cultivos por similitud de riesgo
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-cluster>


La matriz de correlación @fig-cluster entre rentabilidades agrícolas revela patrones significativos para la gestión de riesgos en el sector. La fuerte correlación positiva entre cultivos como el guineo y el plátano indica que estos productos tienden a comportarse de manera similar ante cambios en el mercado y condiciones climáticas, limitando su efectividad para la diversificación de riesgos. En contraste, cultivos como el arroz y la berenjena, que muestran correlaciones bajas o negativas con otros rubros, representan oportunidades valiosas para la diversificación del portafolio agrícola, permitiendo mitigar el impacto de fluctuaciones adversas en el mercado. Esta distinción entre cultivos altamente correlacionados y aquellos con baja correlación proporciona una base fundamental para desarrollar estrategias de producción más resilientes, especialmente cuando se combina la producción de cultivos complementarios que responden de manera diferente a las condiciones del mercado y factores climáticos.

#pagebreak()
= Resultados
<resultados>
La siguiente sección presenta la estimación de ponderaciones óptimas se realizó para determinar la composición del portafolio agrícola correspondiente al primer trimestre de 2023. El análisis se fundamenta en datos históricos del período 2002-2022, a partir de los cuales se estimaron los retornos medios y la varianza de la canasta de cultivos seleccionados. Se estableció una tasa libre de riesgo del 8%, calculada como la media redondeada de la tasa de los instrumentos a un año del Banco Central durante el período de estudio. Las ponderaciones resultantes representan la distribución óptima de cultivos a implementar en 2023.

El análisis de resultados se estructura en dos componentes principales. El primero comprende la estimación del portafolio de máximo rendimiento ajustado por riesgo, visualizado mediante la frontera eficiente y determinado por el punto de tangencia con la Línea del Mercado de Capitales (CML). Este componente incluye un análisis detallado de las características estadísticas del portafolio resultante, incluyendo media, desviación estándar y CVaR en diversos niveles de confianza, validando los resultados mediante su correlación con el análisis exploratorio de rentabilidades.

El segundo componente examina la evolución de las ponderaciones en función de las preferencias de riesgo del agricultor. Este análisis evalúa la robustez de la optimización al examinar cómo varían las asignaciones de cultivos ante cambios en las ponderaciones del riesgo del portafolio y en las métricas de riesgo seleccionadas por el agricultor.

== Estimación del portafolio de máximo Sharpe Ratio
<estimación-del-portafolio-de-máximo-sharpe-ratio>
=== La Frontera Eficiente del Portafolio Agrícola
<la-frontera-eficiente-del-portafolio-agrícola>
#figure([
#box(image("notebooks/opt/efficient-frontier-plot.png"))
], caption: figure.caption(
position: bottom, 
[
Frontera eficiente
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-efficient-frontier-plot>


La resolución iterativa del problema de optimización para diferentes niveles de riesgo genera el conjunto de portafolios que conforman la frontera eficiente, representada en la gráfica @fig-efficient-frontier-plot por la curva amarilla. Esta curva ilustra la relación fundamental entre riesgo y rendimiento en el contexto de la diversificación agrícola, donde cada punto representa una combinación óptima de cultivos para un nivel específico de riesgo.

La geometría de la frontera eficiente estimada exhibe características particulares que merecen atención. Iniciando en el extremo inferior izquierdo, donde se encuentra el portafolio de mínima varianza con una desviación estándar cercana al 1000%, la curva asciende de manera cóncava hasta alcanzar retornos esperados superiores al 150000%. Esta concavidad refleja los rendimientos marginales decrecientes en la relación riesgo-retorno: a medida que se incrementa el riesgo asumido, los aumentos en el retorno esperado son proporcionalmente menores.

El portafolio óptimo, señalado con una estrella roja en la gráfica, se ubica en el punto de tangencia entre la frontera eficiente y la Línea del Mercado de Capitales (CML). Este punto específico, con una desviación estándar aproximada de 2000% y un retorno esperado de 65000%, representa la combinación de cultivos que maximiza el ratio de Sharpe, ofreciendo la mejor compensación entre riesgo y rendimiento dado el entorno de mercado y la tasa libre de riesgo establecida del 8%.

La magnitud de los valores observados en los ejes requiere una contextualización específica: las elevadas cifras de retorno y riesgo son características inherentes del sector agrícola, donde la variabilidad climática y las condiciones de mercado pueden generar fluctuaciones significativas en los resultados financieros. Esta volatilidad intrínseca subraya la importancia crítica de una diversificación óptima en la planificación agrícola. Es pertinente señalar que, si bien pueden existir limitaciones en los datos de entrada utilizados, estas no comprometen la robustez metodológica del análisis ni la validez de las conclusiones obtenidas.

=== Composición del Portafolio Óptimo
<composición-del-portafolio-óptimo>
#figure([
#box(image("notebooks/opt/pie_plot.png"))
], caption: figure.caption(
position: bottom, 
[
Ponderación de la cartera óptima
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-pie-plot>


El portafolio óptimo, representado en la gráfica @fig-pie-plot identificado mediante la optimización de Markowitz exhibe una distribución significativa en cuatro cultivos principales: Auyama (34.2%), Yautía (29.0%), Guineo (28.4%) y Aguacate (6.1%), con el restante 2.3% distribuido entre otros rubros. Esta composición refleja una estrategia sofisticada de optimización que equilibra la maximización del retorno esperado con la gestión efectiva del riesgo mediante diversificación.

La asignación de pesos demuestra una marcada preferencia por cultivos de alta rentabilidad esperada, donde la Auyama, el Aguacate y la Yautía se encuentran entre los cuatro cultivos más rentables del universo analizado. Sin embargo, la inclusión del Guineo, que presenta una rentabilidad esperada negativa, revela la importancia de las correlaciones en la construcción del portafolio. El Guineo exhibe una correlación negativa significativa con la Auyama, actuando como una cobertura natural contra las fluctuaciones adversas en el rendimiento del cultivo principal.

Este patrón de diversificación se sustenta en la estructura de correlaciones observada en el mapa de calor presentado. Los cultivos seleccionados mantienen correlaciones moderadas entre sí (aproximadamente 0.25 entre Auyama, Yautía y Aguacate), mientras que el Guineo proporciona el beneficio adicional de la correlación negativa. Esta estrategia de diversificación permite al portafolio mantener un perfil de riesgo-retorno favorable, donde las pérdidas potenciales en un cultivo pueden ser compensadas por el rendimiento positivo en otros.

La asignación residual del 2.3% a otros cultivos representa un refinamiento adicional en la diversificación, aunque su impacto marginal en la reducción del riesgo del portafolio es limitado debido a sus mayores correlaciones con los componentes principales. Esta estructura de portafolio resultante demuestra la efectividad del modelo de optimización en la identificación de una combinación de cultivos que maximiza el ratio de Sharpe mientras mantiene una exposición controlada a los diversos factores de riesgo del mercado agrícola.

=== Estadísticas descriptivas del portafolio óptimo
<estadísticas-descriptivas-del-portafolio-óptimo>
#figure([
#box(image("notebooks/opt/efficient_frontier_by_risk.png"))
], caption: figure.caption(
position: bottom, 
[
Histograma de los rendimientos del portafolio eficiente
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-histogram>


Como se puede observar en @fig-histogram, el análisis de la distribución de retornos del portafolio óptimo revela características estadísticas fundamentales para la planificación agrícola efectiva. El portafolio muestra un retorno esperado notable de 252.57%, acompañado de una desviación estándar de 105.05%, lo que resulta en un ratio de Sharpe de 2.40. Este nivel de eficiencia en la relación riesgo-retorno es particularmente destacable cuando se compara con referencias de mercado establecidas: el ratio Sharpe del S&P 500 para 2024 es de 2.05, lo que sugiere que la estrategia de diversificación agrícola propuesta logra una eficiencia comparable a la del mercado de valores estadounidense. Obviamente, sin considerar los riesgos de liquidez implícitos que existen en la inversión agrícola con respecto a la inversión bursátil.

Las medidas alternativas de dispersión ofrecen una perspectiva más profunda sobre la variabilidad de los retornos. La Desviación Media Absoluta (MAD) de 78.69% y la Desviación Media Geométrica (GMD) de 119.87% reflejan la naturaleza asimétrica de los retornos agrícolas, una característica inherente al sector debido a múltiples factores. Esta asimetría surge principalmente de la exposición a riesgos climáticos no lineales, la estacionalidad de la producción, y las dinámicas de precios en mercados agrícolas. La diferencia significativa entre MAD y GMD evidencia la presencia de eventos extremos que requieren especial atención en la gestión de riesgos.

Las métricas de riesgo proporcionan información crucial para la planificación de contingencias. El Valor en Riesgo (VaR) al 95% de confianza indica una pérdida máxima potencial de 70.58%, mientras que el CVaR señala una pérdida esperada de 18.02% en el 5% de los escenarios más adversos. Esta cuantificación del riesgo tiene implicaciones prácticas directas: por ejemplo, sugiere que la cobertura de seguros podría optimizarse para proteger contra pérdidas máximas del 70.58%, en lugar de asegurar el valor total de la producción, resultando en una gestión más eficiente de los costos de protección.

Las medidas de riesgo de cola complementarias, EVaR (15.86%) y RLVaR (15.66%), junto con la peor realización histórica observada de 15.40%, confirman la robustez de la estrategia de diversificación. La convergencia de estas métricas alrededor del 15-18% sugiere que, incluso en escenarios extremadamente adversos, las pérdidas se mantienen en niveles manejables para operaciones agrícolas adecuadamente capitalizadas. Este perfil de riesgo es especialmente relevante para la sostenibilidad operativa, ya que permite mantener un flujo de caja estable incluso durante períodos desfavorables.

La asimetría positiva en la distribución de retornos, evidenciada por la diferencia sustancial entre la media y las medidas de riesgo de cola, indica que el portafolio está estructurado para capturar beneficios significativos en condiciones favorables de mercado mientras mantiene una protección efectiva contra pérdidas extremas. Esta característica es fundamental para la viabilidad a largo plazo de las operaciones agrícolas, donde la resiliencia ante condiciones adversas es tan crucial como la capacidad de aprovechar oportunidades de mercado favorables.

== Análisis de sensibilidad
<análisis-de-sensibilidad>
=== Cambios de la estructura del portafolio ante variaciones de la varianza deseada
<cambios-de-la-estructura-del-portafolio-ante-variaciones-de-la-varianza-deseada>
#figure([
#box(image("notebooks/opt/efficient_frontier_by_risk.png"))
], caption: figure.caption(
position: bottom, 
[
Portafolio óptimo según el nivel de riesgo
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-efficient-frontier-by-risk>


La estructura de la frontera eficiente, ilustrada en la gráfica @fig-efficient-frontier-by-risk, presenta la evolución de las ponderaciones de cada cultivo a medida que aumenta el riesgo esperado del portfolio.

El portfolio de mínima varianza, ubicado en el extremo izquierdo de la gráfica, está compuesto principalmente por arroz, guineo y yuca, exhibiendo rendimientos marginalmente negativos pero con volatilidad extraordinariamente baja, lo cual se refleja en las áreas dominantes de estos cultivos en la parte inicial del gráfico de estructura de activos. En contraste, el portfolio de máximo retorno, situado en el extremo derecho, concentra la inversión exclusivamente en auyama, visualizado por el área naranja que domina completamente la composición en este extremo.

La transición entre estos extremos demuestra dos efectos fundamentales: primero, partiendo del portfolio de mínima varianza, se observa una diversificación progresiva que optimiza la relación riesgo-retorno, evidenciada por la distribución más equilibrada de las áreas coloreadas en la sección media del gráfico; segundo, desde el portfolio de máximo retorno, se evidencia una incorporación sistemática de cultivos, visualizada por la gradual reducción del área naranja de la auyama y la aparición de otros cultivos en la composición.

La convergencia de estas dinámicas encuentra su punto óptimo en el portfolio señalado con una estrella en la segunda gráfica de la frontera eficiente media-varianza, correspondiendo a una composición diversificada que se puede observar en la sección media del gráfico de estructura de activos. Este comportamiento subraya el balance entre diversificación y rendimiento esperado, claramente visible en la distribución más equilibrada de las áreas de cultivos en esta sección del gráfico.

=== Cambios de la estructura del portfolio ante diferentes metodologías de medición de riesgo.
<cambios-de-la-estructura-del-portfolio-ante-diferentes-metodologías-de-medición-de-riesgo.>
#figure([
#box(image("notebooks/opt/wheights-by-risk-metric-plot.png"))
], caption: figure.caption(
position: bottom, 
[
Pesos por rubro según la métrica de riesgo
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-wheights-by-risk-metric-plot>


Las diferentes medidas de riesgo capturan distintas características de la distribución de los retornos, cada una enfatizando aspectos específicos del riesgo financiero. Las medidas tradicionales como la desviación estándar y la desviación absoluta media evalúan la dispersión total de los retornos, considerando tanto movimientos positivos como negativos como riesgosos. En contraste, medidas asimétricas como la semi-desviación estándar y los momentos parciales inferiores se concentran exclusivamente en la dispersión por debajo de un umbral objetivo, reconociendo que la volatilidad al alza no representa un verdadero riesgo para el inversionista. Las medidas basadas en drawdown y las medidas de valor en riesgo capturan características más específicas del riesgo a la baja, donde las primeras evalúan las pérdidas acumuladas desde máximos históricos, siendo particularmente relevantes para identificar períodos sostenidos de pérdidas, mientras que las segundas se enfocan en cuantificar las pérdidas extremas en la cola de la distribución.

Como se observa en la @fig-wheights-by-risk-metric-plot, la elección de la medida de riesgo tiene implicaciones sustanciales en la composición óptima del portfolio. El portfolio optimizado bajo desviación estándar (MV) asigna una ponderación significativa al guineo (28.41%) a pesar de sus rendimientos esperados negativos, lo cual se explica por su baja volatilidad total y sus correlaciones negativas o cercanas a cero con otros cultivos, particularmente con la auyama (34.25%), que es el activo de mayor rendimiento. Sin embargo, las medidas de riesgo asimétrico y a la baja, como el CVaR y EVaR, reducen significativamente la exposición al guineo a 7.86%, mientras concentran la inversión en yautía (82.49%). Esta divergencia en las ponderaciones refleja cómo las diferentes medidas de riesgo capturan distintos aspectos de la incertidumbre: mientras la desviación estándar busca minimizar la volatilidad total del portfolio, las medidas de riesgo a la baja se enfocan en mitigar específicamente las pérdidas extremas, resultando en composiciones de portfolio sustancialmente diferentes.

La selección de la medida de riesgo más apropiada debe alinearse con las prácticas agrícolas establecidas y las preferencias específicas del agricultor. Por ejemplo, un agricultor que tradicionalmente ha diversificado sus cultivos para mantener una producción estable podría encontrar más útil la optimización basada en desviación estándar, que como se observa en la @fig-wheights-by-risk-metric-plot, presenta una distribución más equilibrada entre los cultivos. Por otro lado, un agricultor que depende de líneas de crédito estacionales o que enfrenta restricciones de flujo de efectivo podría preferir medidas como el CVaR o el drawdown máximo, concentran las inversiones en cultivos con menor probabilidad de pérdidas extremas. La elección final de la medida de riesgo debe considerar no solo las características matemáticas de cada métrica, sino también cómo estas se alinean con los objetivos operativos y las restricciones prácticas del agricultor.

#pagebreak()
= Conclusiones
<conclusiones>
La presente investigación ha desarrollado una metodología innovadora para optimizar la selección de cultivos en el contexto agrícola dominicano, adaptando la Teoría Moderna de Portafolios de Markowitz. Los resultados demuestran que esta aproximación puede generar una mejora sustancial en la gestión del riesgo y la rentabilidad agrícola, sin requerir inversiones significativas en tecnificación o cambios estructurales en las prácticas existentes.

El portafolio óptimo identificado, compuesto principalmente por Auyama (34.2%), Yautía (29.0%), Guineo (28.4%) y Aguacate (6.1%), logra un ratio de Sharpe de 2.40, superando incluso referencias de mercado establecidas como el S&P 500. Esta composición no solo maximiza los retornos esperados sino que también proporciona una protección efectiva contra pérdidas extremas, con un Valor en Riesgo (VaR) del 70.58% y un CVaR del 18.02%, niveles manejables para operaciones agrícolas adecuadamente capitalizadas.

El análisis de sensibilidad revela que la estructura óptima del portafolio es robusta ante diferentes medidas de riesgo, aunque las ponderaciones específicas varían según la métrica utilizada. Esto sugiere que la metodología puede adaptarse a diferentes perfiles de riesgo y preferencias de los agricultores, manteniendo su efectividad como herramienta de optimización.

La investigación demuestra que la diversificación sistemática basada en correlaciones entre cultivos puede mejorar significativamente la resiliencia económica de las explotaciones agrícolas. Este enfoque representa una innovación importante en la gestión agrícola dominicana, proporcionando una herramienta práctica para optimizar la selección de cultivos sin requerir cambios fundamentales en las prácticas existentes o inversiones significativas de capital.

Las implicaciones de estos hallazgos son particularmente relevantes para el contexto dominicano, donde las limitaciones de capital y acceso a instrumentos financieros sofisticados han sido históricamente barreras para la modernización agrícola. La metodología propuesta ofrece una vía de mejora que es tanto práctica como accesible, permitiendo a los agricultores maximizar sus retornos y gestionar riesgos de manera más efectiva dentro de sus restricciones existentes.

#pagebreak()
= Anexos
<anexos>
#block[
#table(
  columns: 13,
  align: (auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,),
  table.header([~], [Aguacate], [Arroz], [Auyama], [Batata], [Berenjena], [Guineo], [Maíz], [Papa], [Plátano], [Yautía], [Yuca], [Ñame],),
  table.hline(),
  [weights], [0.06%], [0.00%], [0.34%], [0.00%], [0.00%], [0.28%], [0.00%], [0.02%], [0.00%], [0.29%], [0.00%], [0.00%],
)
]
#block[
#table(
  columns: 14,
  align: (auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,auto,),
  table.header([~], [MV], [MAD], [MSV], [FLPM], [SLPM], [CVaR], [EVaR], [WR], [MDD], [ADD], [CDaR], [UCI], [EDaR],),
  table.hline(),
  [Aguacate], table.cell(fill: rgb("#ebf7b0"))[#set text(fill: rgb("#000000")); 6.10%], table.cell(fill: rgb("#fdfeda"))[#set text(fill: rgb("#000000")); 2.01%], table.cell(fill: rgb("#fcfed7"))[#set text(fill: rgb("#000000")); 2.14%], table.cell(fill: rgb("#ebf7b0"))[#set text(fill: rgb("#000000")); 7.04%], table.cell(fill: rgb("#f6fcb8"))[#set text(fill: rgb("#000000")); 5.57%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fbfed2"))[#set text(fill: rgb("#000000")); 4.34%], table.cell(fill: rgb("#f6fcb8"))[#set text(fill: rgb("#000000")); 5.93%], table.cell(fill: rgb("#f9fdc5"))[#set text(fill: rgb("#000000")); 5.22%], table.cell(fill: rgb("#fbfdcf"))[#set text(fill: rgb("#000000")); 4.58%], table.cell(fill: rgb("#fdfedd"))[#set text(fill: rgb("#000000")); 3.32%],
  [Arroz], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fdfedd"))[#set text(fill: rgb("#000000")); 1.46%], table.cell(fill: rgb("#feffde"))[#set text(fill: rgb("#000000")); 1.24%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe4"))[#set text(fill: rgb("#000000")); 2.54%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 1.64%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 2.31%], table.cell(fill: rgb("#ffffe4"))[#set text(fill: rgb("#000000")); 2.60%], table.cell(fill: rgb("#feffe1"))[#set text(fill: rgb("#000000")); 2.83%],
  [Auyama], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 34.25%], table.cell(fill: rgb("#e0f3a8"))[#set text(fill: rgb("#000000")); 13.56%], table.cell(fill: rgb("#6bc072"))[#set text(fill: rgb("#000000")); 26.92%], table.cell(fill: rgb("#208242"))[#set text(fill: rgb("#f1f1f1")); 27.86%], table.cell(fill: rgb("#8bce81"))[#set text(fill: rgb("#000000")); 18.70%], table.cell(fill: rgb("#f8fcbd"))[#set text(fill: rgb("#000000")); 9.64%], table.cell(fill: rgb("#f8fcbd"))[#set text(fill: rgb("#000000")); 9.64%], table.cell(fill: rgb("#f8fcbd"))[#set text(fill: rgb("#000000")); 9.64%], table.cell(fill: rgb("#b2df90"))[#set text(fill: rgb("#000000")); 15.49%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 34.39%], table.cell(fill: rgb("#4cb063"))[#set text(fill: rgb("#f1f1f1")); 21.47%], table.cell(fill: rgb("#9fd788"))[#set text(fill: rgb("#000000")); 16.32%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 43.12%],
  [Batata], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#f4fbb7"))[#set text(fill: rgb("#000000")); 5.54%], table.cell(fill: rgb("#f7fcbc"))[#set text(fill: rgb("#000000")); 5.13%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fafdcc"))[#set text(fill: rgb("#000000")); 5.00%], table.cell(fill: rgb("#f2fab5"))[#set text(fill: rgb("#000000")); 6.49%], table.cell(fill: rgb("#f9fdc2"))[#set text(fill: rgb("#000000")); 5.42%], table.cell(fill: rgb("#fafdc8"))[#set text(fill: rgb("#000000")); 5.26%], table.cell(fill: rgb("#fcfed4"))[#set text(fill: rgb("#000000")); 4.26%],
  [Berenjena], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fcfed3"))[#set text(fill: rgb("#000000")); 2.54%], table.cell(fill: rgb("#fbfed0"))[#set text(fill: rgb("#000000")); 2.76%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fdfedd"))[#set text(fill: rgb("#000000")); 3.28%], table.cell(fill: rgb("#feffde"))[#set text(fill: rgb("#000000")); 2.38%], table.cell(fill: rgb("#fdfedd"))[#set text(fill: rgb("#000000")); 3.08%], table.cell(fill: rgb("#fdfedb"))[#set text(fill: rgb("#000000")); 3.30%], table.cell(fill: rgb("#fcfed7"))[#set text(fill: rgb("#000000")); 3.97%],
  [Guineo], table.cell(fill: rgb("#0c723b"))[#set text(fill: rgb("#f1f1f1")); 28.41%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 61.78%], table.cell(fill: rgb("#a2d88a"))[#set text(fill: rgb("#000000")); 20.22%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.61%], table.cell(fill: rgb("#fafdcb"))[#set text(fill: rgb("#000000")); 3.42%], table.cell(fill: rgb("#f9fdc4"))[#set text(fill: rgb("#000000")); 7.86%], table.cell(fill: rgb("#f9fdc4"))[#set text(fill: rgb("#000000")); 7.86%], table.cell(fill: rgb("#f9fdc4"))[#set text(fill: rgb("#000000")); 7.86%], table.cell(fill: rgb("#f8fcbe"))[#set text(fill: rgb("#000000")); 6.34%], table.cell(fill: rgb("#f9fdc4"))[#set text(fill: rgb("#000000")); 4.79%], table.cell(fill: rgb("#f8fcc0"))[#set text(fill: rgb("#000000")); 5.62%], table.cell(fill: rgb("#f8fcbd"))[#set text(fill: rgb("#000000")); 6.27%], table.cell(fill: rgb("#fafdcb"))[#set text(fill: rgb("#000000")); 5.40%],
  [Maíz], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#feffde"))[#set text(fill: rgb("#000000")); 1.44%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.34%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 2.31%], table.cell(fill: rgb("#feffe2"))[#set text(fill: rgb("#000000")); 1.92%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 2.23%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 2.34%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 2.24%],
  [Papa], table.cell(fill: rgb("#fbfdcf"))[#set text(fill: rgb("#000000")); 2.27%], table.cell(fill: rgb("#fdfedd"))[#set text(fill: rgb("#000000")); 1.52%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#f9fdc5"))[#set text(fill: rgb("#000000")); 3.94%], table.cell(fill: rgb("#f9fdc5"))[#set text(fill: rgb("#000000")); 4.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fcfed7"))[#set text(fill: rgb("#000000")); 3.79%], table.cell(fill: rgb("#fafdcc"))[#set text(fill: rgb("#000000")); 3.96%], table.cell(fill: rgb("#fbfed2"))[#set text(fill: rgb("#000000")); 3.98%], table.cell(fill: rgb("#fcfed7"))[#set text(fill: rgb("#000000")); 3.71%], table.cell(fill: rgb("#fdfedb"))[#set text(fill: rgb("#000000")); 3.50%],
  [Plátano], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.73%], table.cell(fill: rgb("#fbfdcf"))[#set text(fill: rgb("#000000")); 2.89%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#fbfdce"))[#set text(fill: rgb("#000000")); 4.88%], table.cell(fill: rgb("#fbfed2"))[#set text(fill: rgb("#000000")); 3.56%], table.cell(fill: rgb("#fbfdce"))[#set text(fill: rgb("#000000")); 4.35%], table.cell(fill: rgb("#fafdc9"))[#set text(fill: rgb("#000000")); 5.06%], table.cell(fill: rgb("#fcfed4"))[#set text(fill: rgb("#000000")); 4.31%],
  [Yautía], table.cell(fill: rgb("#086e3a"))[#set text(fill: rgb("#f1f1f1")); 28.96%], table.cell(fill: rgb("#fbfdce"))[#set text(fill: rgb("#000000")); 4.19%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 50.72%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 36.51%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 40.64%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 82.49%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 82.49%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 82.49%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 38.87%], table.cell(fill: rgb("#288a47"))[#set text(fill: rgb("#f1f1f1")); 25.46%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 34.24%], table.cell(fill: rgb("#004529"))[#set text(fill: rgb("#f1f1f1")); 36.67%], table.cell(fill: rgb("#c7e89a"))[#set text(fill: rgb("#000000")); 14.67%],
  [Yuca], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#eff9b3"))[#set text(fill: rgb("#000000")); 6.23%], table.cell(fill: rgb("#edf8b2"))[#set text(fill: rgb("#000000")); 7.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#f8fdc1"))[#set text(fill: rgb("#000000")); 6.13%], table.cell(fill: rgb("#f8fcbd"))[#set text(fill: rgb("#000000")); 5.47%], table.cell(fill: rgb("#f7fcbc"))[#set text(fill: rgb("#000000")); 6.05%], table.cell(fill: rgb("#f7fcba"))[#set text(fill: rgb("#000000")); 6.55%], table.cell(fill: rgb("#fafdc8"))[#set text(fill: rgb("#000000")); 5.61%],
  [Ñame], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#d0ec9f"))[#set text(fill: rgb("#000000")); 16.94%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#f0f9b4"))[#set text(fill: rgb("#000000")); 6.10%], table.cell(fill: rgb("#e6f5ac"))[#set text(fill: rgb("#000000")); 8.32%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#ffffe5"))[#set text(fill: rgb("#000000")); 0.00%], table.cell(fill: rgb("#f6fcb8"))[#set text(fill: rgb("#000000")); 7.03%], table.cell(fill: rgb("#fafdcc"))[#set text(fill: rgb("#000000")); 4.02%], table.cell(fill: rgb("#f7fcbc"))[#set text(fill: rgb("#000000")); 6.04%], table.cell(fill: rgb("#f2fab5"))[#set text(fill: rgb("#000000")); 7.32%], table.cell(fill: rgb("#f8fcbe"))[#set text(fill: rgb("#000000")); 6.77%],
)
]
#figure([
#box(image("notebooks/eda/costs_by_crop.png"))
], caption: figure.caption(
position: bottom, 
[
Evolución de los Costos de Producción por Rubros Agrícolas, 2002-2022
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-costs_by_crop>


#figure([
#box(image("notebooks/eda/prices_by_crop.png"))
], caption: figure.caption(
position: bottom, 
[
Evolución de los Precios de Venta por Rubros Agrícolas, 2002-2022
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-price_by_crop>


#figure([
#box(image("notebooks/eda/profitability_by_crop.png"))
], caption: figure.caption(
position: bottom, 
[
Evolución de las Rentabilidades por Rubros Agrícolas, 2002-2022
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-profit_by_crop>


#pagebreak()




#bibliography("references.bib")

