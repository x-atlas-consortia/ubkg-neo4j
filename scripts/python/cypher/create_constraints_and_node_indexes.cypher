MATCH (n:Term) WHERE count{(n)--()}=0 DELETE (n);
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.TUI IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.STN IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.DEF IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT FOR (n:Concept) REQUIRE n.CUI IS UNIQUE;
CREATE CONSTRAINT FOR (n:Code) REQUIRE n.CodeID IS UNIQUE;
CREATE INDEX FOR (n:Code) ON (n.SAB);
CREATE INDEX FOR (n:Code) ON (n.CODE);
CREATE INDEX FOR (n:Term) ON (n.name);
CREATE INDEX FOR (n:Definition) ON (n.SAB);
//March 2025 fulltext on term.name
CREATE FULLTEXT termNames FOR (t:Term) ON EACH [t.name]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: true
  }
};