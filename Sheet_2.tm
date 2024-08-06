<TeXmacs|2.1.4>

<style|generic>

<\body>
  <doc-data|<doc-title|Day 2: Basics of Quantum
  Mechanics>|<doc-author|<author-data|<author-name|Philip Schwinghammer and
  Paul Nemec>>>|<doc-author|<author-data>>>

  <section|Axioms of Quantum Mechanics>

  <subsection|States are Vectors>

  We can represent the state of a quantum system (the system is whatever
  we're looking at, for example a single electron in a box) as a vector of
  complex numbers. The system is parametrized by one or more variables, such
  as position of the electron in the box. The state of the system is then
  given by the values of all such variables. The space of all possible such
  vectors is called a <with|font-shape|italic|Hilbert space>, and is denoted
  by <math|\<cal-H\>>. The simplest example is a single spin
  <math|\<sigma\>>, which can either point up or down. Since there are two
  possible states, the vector describing the system has two entries, which we
  will call \Pup\Q <math|\<sigma\>=<around*|\||+|\<rangle\>>> and down
  <math|\<sigma\>=<around*|\||-|\<rangle\>>>.\ 

  It is convenient to represent vectors in the same way you may know from
  geometry, as brackets with entries for each dimension. We identify:

  <\equation*>
    <around*|\||+|\<rangle\>>=*<matrix|<tformat|<table|<row|<cell|1>>|<row|<cell|0>>>>><text|>
  </equation*>

  <\equation*>
    <around*|\||-|\<rangle\>>=*<matrix|<tformat|<table|<row|<cell|0>>|<row|<cell|1>>>>><text|>
  </equation*>

  State-vectors <math|<with|font-series|bold|a>,<with|font-series|bold|b>\<in\>\<cal-H\>>
  for a quantum mechanical system can be added together, with prefixes of
  complex numbers <math|c<rsub|1,2>\<in\>\<bbb-C\>>:

  <\equation*>
    c<rsub|1>\<cdot\><with|font-series|bold|a>+c<rsub|2>\<cdot\>
    <with|font-series|bold|b>
  </equation*>

  They have a scalar product (with <math|a<rsub|i>> and <math|b<rsub|i>>
  being the entries of the vectors, numbered from 1 to <math|N>):

  <\equation*>
    <with|font-series|bold|a>\<cdot\><with|font-series|bold|b>=<big|sum><rsub|i>a<rsub|\<iota\>><rsup|*\<ast\>>\<cdot\>b<rsub|\<iota\>>
  </equation*>

  A convenient notation is the bra-ket notation, where we write a vector as
  the <with|font-shape|italic|ket> <math|<around*|\||v|\<rangle\>>\<in\>\<cal-H\>>,
  and the <with|font-shape|italic|conjugate> of the vector as the
  <with|font-shape|italic|bra> <math|<around*|\<langle\>|v|\|>\<in\>\<cal-H\>>.
  Taking the conjugate of a vector is what we do when we want to calculate
  the scalar product:\ 

  <\equation*>
    <around*|\<langle\>|a\|b|\<rangle\>>=<big|sum><rsub|i>a<rsub|\<iota\>><rsup|\<ast\>>\<cdot\>b<rsub|\<iota\>>.
  </equation*>

  The scalar product fulfils a few properties that uniquely define it:

  <subsubsection|Properties of the Scalar product>

  <\enumerate-numeric>
    <item>It is <with|font-shape|italic|sesquilinear>. We denote the sum of
    two vectors inside the same bra/ket as
    <math|<around*|\<langle\>|a+b\|\<in\>\<cal-H\>|\<nobracket\>>>, and
    multiplication with a complex number <math|c<rsub|1>\<in\>\<bbb-C\>> is
    written as <math|<around*|\||c<rsub|1>\<cdot\>a|\<rangle\>>=c<rsub|1><around*|\||a|\<rangle\>>>.\ 

    <\equation*>
      <math|<around*|\<langle\>|a+c<rsub|1>\<cdot\>b\|c|\<rangle\>>=<around*|\<langle\>|a\|c|\<rangle\>>+c<rsub|1><rsup|*\<ast\>>*<around*|\<langle\>|b\|c|\<rangle\>>>
      and <math|<around*|\<langle\>|a\|c<rsub|1>\<cdot\>b+c|\<rangle\>>=<around*|\<langle\>|a\|b|\<rangle\>>+c<rsub|1><around*|\<langle\>|a\|c|\<rangle\>>>
    </equation*>

    Note that pulling a complex number out of a bra will turn it into its
    complex conjugate! That is why it is only sesquilinear, not fully linear.\ 

    <item>It is <with|font-shape|italic|hermitian>. That means that
    exchanging which vector is the bra and which is the ket will give the
    complex conjugate of the scalar product:

    <\equation*>
      <around*|\<langle\>|a\|b|\<rangle\>>=<around*|\<langle\>|b\|a|\<rangle\>><rsup|\<ast\>>
    </equation*>

    <item>It is positive definite. That means the scalar product of a vector
    <math|<around*|\||a|\<rangle\>>\<in\>\<cal-H\>> with itself will always
    be positive, unless the vector is zero, in which case it is zero.\ 

    <\equation*>
      <around*|\<langle\>|a\|a|\<rangle\>>\<gtr\>0<space|1em>for
      a\<neq\>0<infix-and><around*|\<langle\>|0\|0|\<rangle\>>=0.
    </equation*>

    \;
  </enumerate-numeric>

  <subsubsection|The norm of a state>

  The norm of any quantum state <math|<around*|\||v|\<rangle\>>\<in\>\<cal-H\>>
  is given by the square root of its scalar product with itself:

  <\equation*>
    <around*|\<\|\|\>|v|\<\|\|\>>=<sqrt|<around*|\<langle\>|v\|v|\<rangle\>>>
  </equation*>

  In quantum mechanics, usually we assume that states are
  <with|font-shape|italic|normalised>. This means that the norm (or length)
  of the state vector is 1.\ 

  <subsubsection|Orthogonality>

  We call two states <math|<around*|\||v<rsub|1>|\<rangle\>>,<around*|\||v<rsub|2>|\<rangle\>>\<in\>\<cal-H\>>
  <with|font-shape|italic|orthogonal> if their scalar product is zero:
  <math|<around*|\<langle\>||\<nobracket\>>v<rsub|1><around*|\||v<rsub|2>|\<rangle\>>=0.>

  <subsubsection|Exercises>

  <\question>
    In the Julia Notebook, implement a function which takes two spin-states
    and returns the scalar product.
  </question>

  <\question>
    In the Julia Notebook, implement a function which takes two vectors as
    arguments and returns <with|font-shape|italic|true> if they are
    orthogonal, and <with|font-shape|italic|false> if they are not
    orthogonal.
  </question>

  <\question>
    In the Julia Notebook, implement a function which takes one spin state,
    and returns its norm.\ 
  </question>

  <\question>
    In the Julia Notebook, implement a function which takes a vector, and
    returns the normalised version of this vector.
  </question>

  <\question>
    Keep working through the notebook! Use this as a reference.
  </question>

  <section|Observables as Hermitian Matrices>

  Observables are properties of a system which can be measured (observed).
  Examples include the momentum <math|<with|font-series|bold|p>>, the Energy
  <math|E>, position <math|<with|font-series|bold|x>> and the spin
  <math|\<sigma\>>. In Quantum mechanics the observables are defined through
  Hermitian matrices. Matrices in general can be thought of as defining
  linear transformation. They can be written as\ 

  <\equation*>
    A=<matrix|<tformat|<table|<row|<cell|a<rsub|11>>|<cell|a<rsub|12>>>|<row|<cell|a<rsub|21>>|<cell|a<rsub|22>>>>>>
  </equation*>

  in the case of a 2-dimensional vector space. For <math|N>-dimensional
  vector-spaces we have <math|N\<times\>N> matrices. (In general, matrices
  can also have different lengths and widths, e.g. <math|M\<times\>N>
  matrices, but in quantum mechanics, all Matrices are square)

  The product of a matrix and a vector is defined as

  <\equation*>
    A<around*|\||v|\<rangle\>>=<big|sum><rsub|j=1><rsup|N>a<rsub|i,j>\<cdot\>v<rsub|j><rsub|>
  </equation*>

  This means each entry from the first row of the matrix is multiplied by the
  corresponding entry of the vector. Their sum is the first entry of the new
  vector. Then the same is repeated for the second, third, <text-dots>,
  <math|n>-th row.\ 

  <subsection|Definition of Hermitian Matrices>

  <\enumerate-numeric>
    <item>Hermitian matrices are square

    <item>Exchanging the indices for the entries of the matrix gives the
    complex conjugate:

    <\equation*>
      a<rsub|i,j>=a<rsub|j,i><rsup|\<ast\>>
    </equation*>

    If you prefer to think about the matrix as written out with rows and
    collumns, mirroring it along the diagonal will give the complex conjugate
    of the entries:

    <\equation*>
      A=<matrix|<tformat|<table|<row|<cell|a<rsub|11>>|<cell|a<rsub|12>>>|<row|<cell|a<rsub|12><rsup|*\<ast\>>>|<cell|a<rsub|22>>>>>>
    </equation*>

    \;
  </enumerate-numeric>

  <subsection|Important properties>

  In general, when we multiply a matrix with a vector, we get a completely
  different vector, that points in a different direction. However, there is a
  set of special vectors, the so-called eigenvectors. Each hermitian matrix
  of size <math|N\<times\>N> has <math|N> unique eigenvectors.\ 

  Multiplying an eigenvector <math|<around*|\||v<rsub|i>|\<rangle\>>> with
  the corresponding matrix <math|A> will return the same vector, scaled by a
  number called the <with|font-shape|italic|eigenvalue> <math|a>.\ 

  <\equation*>
    A<around*|\||v<rsub|i>|\<rangle\>>=a<rsub|i><around*|\||v<rsub|i>|\<rangle\>>
  </equation*>

  The eigenvectors of a hermitian matrix are all orthogonal (not generally
  true for different matrices!) and therefore form a
  <with|font-shape|italic|basis> of the vectorspace <math|\<cal-H\>>. A basis
  is a collection of vectors <math|<around*|{|<around*|\||v<rsub|1>|\<rangle\>>,\<ldots\>,<around*|\||v<rsub|N>|\<rangle\>>|}>>,
  such that any vector <math|<around*|\||w|\<rangle\>>> can be written as a
  linear combination of them:

  <\equation*>
    <around*|\||w|\<rangle\>>=<big|sum><rsub|i=1><rsup|N>c<rsub|i><around*|\||v<rsub|i>|\<rangle\>>
  </equation*>

  \;

  <\question>
    Work through the Chapter \PThe Second Axiom: Observables are Hermitian
    Matrices\Q in the Julia Notebook.
  </question>

  <section|Measurements>

  Saying observables are represented by hermitian matrices is all well and
  good, but what does it mean? What happens when we try to measure the
  observable? It turns out that when measuring an observable, it is only
  possible to find the states which are eigenvectors of the hermitian matrix
  associated with that observeable. If the system is in a different state, it
  will <with|font-shape|italic|collapse> into one of the eigenstates (states
  which are eigenvectors). The outcome of the measurement (the measured
  value) is the eigenvalue <math|a<rsub|i>> associated with the eigenstate
  <math|<around*|\||v<rsub|i>|\<rangle\>>>.\ 

  This is the so-called wavefunction collapse, which is the source of many
  philosphical debates about the true nature of quantum mechanics. For our
  purposes, its not that important to know about, but if your interested, you
  can start here: <hlink|https://en.wikipedia.org/wiki/Wave_function_collapse|>

  The outcome of the measurement is determined probabilistically; The
  probability <math|P> to measure any particular eigenvalue <math|a<rsub|i>>
  of an eigenstate <math|<around*|\||v<rsub|i>|\<rangle\>>> is given by the
  scalar product between the pre-measurement state
  <math|<around*|\||\<psi\>|\<rangle\>>> and that eigenstate.\ 

  <\equation*>
    P<around*|(|E|)>=<around*|\||<around*|\<langle\>|v<rsub|e><around*|\|||\<nobracket\>>\<psi\>|\<rangle\>>|\|><rsup|2>
  </equation*>

  <\question>
    Work through the Julia notebook chapter \PThe Third Axiom:
    Measurements\Q.\ 
  </question>

  <section|The Time Evolution>

  The <with|font-shape|italic|time evolution> of any quantum system is
  determined by the <with|font-shape|italic|Schrödinger equation>. When we
  say time evolution what we mean is this:\ 

  Imagine you know the state of the system at time <math|t=0>, e.g. a spin
  which is in the state <math|<around*|\||+|\<rangle\>>>. What state will you
  have at <math|t=1s>? or <math|t=2s>? This is determined by the time
  evolution \V that is, how the state changes over time. (In the Julia
  notebook, you will calculate the time evolution for a spin state such as
  <math|<around*|\||+|\<rangle\>>>.)

  In quantum systems, the time dependent state
  <math|<around*|\||\<Psi\><around*|(|t|)>|\<rangle\>>> is described by the
  Schrödinger equation:\ 

  <\equation*>
    i \<hbar\><frac|\<partial\>|\<partial\>t>
    <around*|\||\<Psi\><around*|(|t|)>|\<rangle\>>=H
    <around*|\||\<Psi\><around*|(|t|)>|\<rangle\>>
  </equation*>

  Here the left side is the derivative with respect to time, and the right
  hand-side is a matrix-multiplication of the matrix <math|H> and the state
  <math|<around*|\||\<Psi\><around*|(|t|)>|\<rangle\>>>. After yesterday,
  this equation will seam familiar for real or complex number <math|H>, and
  it turns out that a matrix is not so different.\ 

  Deriving the solution of the time-dependent Schrödinger equation is left as
  an exercise to the reader, but analogous to yesterday we write it as

  <\equation*>
    <around*|\||\<Psi\><around*|(|t|)>|\<rangle\>>=exp<around*|(|<frac|-i\<cdot\>
    t\<cdot\>H|\<hbar\>>|)><around*|\||\<Psi\><around*|(|0|)>|\<rangle\>>
  </equation*>

  Here the exponential function exp when applied to a matrix is again a
  matrix itself. You'll need to multiply matrices as follows. In the index
  notation introduced earlier, multiplying two matrices <math|A> and <math|B>
  takes this form:

  <\equation*>
    <around*|(|A\<cdot\>B|)><rsub|i,j>=<big|sum><rsub|k>a<rsub|i,k>\<cdot\>b<rsub|k,j>
  </equation*>

  Imagining this in the notation with rows and columns, the first row of the
  first matrix is multiplied element-wise with the first columns of the
  second matrix; This is the first entry of the new matrix. The one goes
  through all combinations of rows and columns to get the further entries, so
  the second row multiplied with the third column is the element with indices
  (2,3) of the new matrix.\ 

  <\equation*>
    A\<cdot\>B=<matrix|<tformat|<table|<row|<cell|a<rsub|11>>|<cell|a<rsub|12>>>|<row|<cell|a<rsub|21>>|<cell|a<rsub|22>>>>>><matrix|<tformat|<table|<row|<cell|b<rsub|11>>|<cell|b<rsub|12>>>|<row|<cell|b<rsub|21>>|<cell|b<rsub|22>>>>>>=<matrix|<tformat|<table|<row|<cell|a<rsub|11>*b<rsub|11>+a<rsub|12>*b<rsub|21>>|<cell|a<rsub|11>*b<rsub|12>+a<rsub|12>*b<rsub|22>>>|<row|<cell|a<rsub|21>*b<rsub|11>+a<rsub|21>*b<rsub|21>>|<cell|a<rsub|21>*b<rsub|12>+a<rsub|22>*b<rsub|22>>>>>>
  </equation*>

  The exponential of a matrix <math|A> can be defined by:

  <\equation*>
    exp<around*|(|A|)>=<big|sum><rsub|n=1><rsup|\<infty\>><frac|1|n!>A<rsup|n>
  </equation*>

  <\question>
    Go to the Julia notebook and finish it!
  </question>

  Things to note:\ 

  <\enumerate-numeric>
    <item>The eigenvectors of the exponentiated matrix and the original
    hermitian matrix are the same. (Why?)

    <item>In general, does the identity <math|exp<around*|(|A+
    B|)>=exp<around*|(|A|)>exp<around*|(|B|)>> hold for matrices? Prove or
    disprove the statement.\ 
  </enumerate-numeric>
</body>

<\initial>
  <\collection>
    <associate|page-medium|paper>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|1>>
    <associate|auto-10|<tuple|3|3>>
    <associate|auto-11|<tuple|4|4>>
    <associate|auto-2|<tuple|1.1|1>>
    <associate|auto-3|<tuple|1.1.1|1>>
    <associate|auto-4|<tuple|1.1.2|2>>
    <associate|auto-5|<tuple|1.1.3|2>>
    <associate|auto-6|<tuple|1.1.4|2>>
    <associate|auto-7|<tuple|2|2>>
    <associate|auto-8|<tuple|2.1|3>>
    <associate|auto-9|<tuple|2.2|3>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|toc>
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|1<space|2spc>Axioms
      of Quantum Mechanics> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <with|par-left|<quote|1tab>|1.1<space|2spc>States are Vectors
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2>>

      <with|par-left|<quote|2tab>|1.1.1<space|2spc>Properties of the Scalar
      product <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <with|par-left|<quote|2tab>|1.1.2<space|2spc>The norm of a state
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <with|par-left|<quote|2tab>|1.1.3<space|2spc>Orthogonality
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <with|par-left|<quote|2tab>|1.1.4<space|2spc>Exercises
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|2<space|2spc>Observables
      as Hermitian Matrices> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <with|par-left|<quote|1tab>|2.1<space|2spc>Definition of Hermitian
      Matrices <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <with|par-left|<quote|1tab>|2.2<space|2spc>Important properties
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|3<space|2spc>Measurements>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|4<space|2spc>The
      Time Evolution> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>