set serveroutput on;
-- creation de la table morpion si elle n'existe pas
DECLARE
  nbta NUMBER;
BEGIN
  SELECT count(*) INTO nbta FROM user_tables 
    WHERE TABLE_NAME = 'MORPION';
  IF nbta = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE morpion(
      y NUMBER,
      A CHAR,
      B CHAR,
      C CHAR
    )';
 END IF;
END;
/
-- fonction de conversion de nombre en nom de colone
CREATE OR REPLACE FUNCTION nbToColName(nb IN NUMBER)
RETURN CHAR
IS
BEGIN
  IF nb=1 THEN
    RETURN 'A';
  ELSIF nb=2 THEN
    RETURN 'B';
  ELSIF nb=3 THEN
    RETURN 'C';
  ELSE 
    RETURN '_';
  END IF;
END;
/
-- procedure pour afficher le plateau de jeu
CREATE OR REPLACE PROCEDURE print_game IS
BEGIN
  dbms_output.enable(10000);
  dbms_output.put_line(' ');
  FOR ll in (SELECT * FROM morpion ORDER BY Y) LOOP
    dbms_output.put_line('     ' || ll.A || ' ' || ll.B || ' ' || ll.C);
  END LOOP; 
  dbms_output.put_line(' ');
END;
/
-- procedure de remise à zero du jeux
CREATE OR REPLACE PROCEDURE reset_game IS
ii NUMBER;
BEGIN
  DELETE FROM morpion;
  FOR ii in 1..3 LOOP
    INSERT INTO morpion VALUES (ii,'_','_','_');
  END LOOP; 
  dbms_output.enable(10000);
  print_game();
  dbms_output.put_line('Le jeu est pret. pour jouer : EXECUTE play(''X'', x, y);');
END;
/
-- procedure pour jouer
CREATE OR REPLACE PROCEDURE play(symbole IN VARCHAR2, colonb IN NUMBER, ligne IN NUMBER) IS
val morpion.a%type;
colo CHAR;
symbole2 CHAR;
BEGIN
  SELECT nbToColName(colonb) INTO colo FROM DUAL;
  EXECUTE IMMEDIATE ('SELECT ' || colo || ' FROM morpion WHERE y=' || ligne) INTO val;
  IF val='_' THEN
    EXECUTE IMMEDIATE ('UPDATE morpion SET ' || colo || '=''' || symbole || ''' WHERE y=' || ligne);
    IF symbole='X' THEN
      symbole2:='O';
    ELSE
      symbole2:='X';
    END IF;
    print_game();
    dbms_output.put_line('Au tour de ' || symbole2 || '. pour jouer : EXECUTE play(''' || symbole2 || ''', x, y);');
  ELSE
    dbms_output.enable(10000);
    dbms_output.put_line('Vous ne pouvez pas jouer cette case, elle est déjà jouée');
  END IF;
END;
/
-- procedure pour gagner
CREATE OR REPLACE PROCEDURE winner(symbole IN VARCHAR2) IS
BEGIN
  dbms_output.enable(10000);
  print_game();
  dbms_output.put_line('Le joueur ' || symbole || ' a gagné !!'); 
  dbms_output.put_line('---------------------------------------');
  dbms_output.put_line('Lancement d''une nouvelle partie...');
  reset_game();
END;
/
-- fonction de creation de requetes de colone
CREATE OR REPLACE FUNCTION wincol_request(nomcol IN VARCHAR2, symbole IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT COUNT(*) FROM morpion WHERE ' || nomcol || ' = '''|| symbole ||''' AND ' || nomcol || ' != ''_''');
END;
/
-- fonction de creation de requetes de colone
CREATE OR REPLACE FUNCTION wincross_request(nomcol IN VARCHAR2, yvalue IN NUMBER)
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT '|| nomcol ||' FROM morpion WHERE y=' || yvalue);
END;
/
-- fonction de test des colones
CREATE OR REPLACE FUNCTION wincol(nomcol IN VARCHAR2)
RETURN CHAR
IS
  nbwin NUMBER;
  r VARCHAR2(56);
BEGIN
  SELECT wincol_request(nomcol, 'X') into r FROM DUAL;
  EXECUTE IMMEDIATE r INTO nbwin;
  IF nbwin=3 THEN
    RETURN 'X';
  ELSIF nbwin=0 THEN
    SELECT wincol_request(nomcol, 'O') into r FROM DUAL;
    EXECUTE IMMEDIATE r INTO nbwin;
    IF nbwin=3 THEN
      RETURN 'O';
    END IF;
  END IF;
  RETURN '_';
END;
/
-- fonction de test des diagonales
CREATE OR REPLACE FUNCTION wincross(tmpx IN CHAR, numcol IN NUMBER, numligne IN NUMBER)
RETURN CHAR
IS
  tmpvar CHAR;
  tmpxvar CHAR;
  r VARCHAR2(56);
BEGIN
  SELECT wincross_request(nbToColName(numcol), numligne) INTO r FROM DUAL;
  IF tmpx IS NULL THEN
    EXECUTE IMMEDIATE (r) INTO tmpxvar;
  ELSIF NOT tmpx = '_' THEN
    EXECUTE IMMEDIATE (r) INTO tmpvar;
    IF NOT tmpx = tmpvar THEN
      tmpxvar := '_';
    END IF;
  ELSE
    tmpxvar := '_';
  END IF;
  RETURN tmpxvar;
END;
/
-- trigger de test si on gagne
CREATE OR REPLACE TRIGGER iswinner
AFTER UPDATE ON morpion
DECLARE
  CURSOR cr_ligne IS 
    SELECT * FROM morpion ORDER BY Y; 
  crlv morpion%rowtype;
  tmpvar CHAR;
  tmpx1 CHAR;
  tmpx2 CHAR;
  r VARCHAR2(40);
BEGIN
  FOR crlv IN cr_ligne LOOP
    -- test des lignes
    IF crlv.A = crlv.B AND crlv.B = crlv.C AND NOT crlv.A='_' THEN
      winner(crlv.A);
      EXIT;
    END IF;
    -- test des colones
    SELECT wincol(nbToColName(crlv.Y)) INTO tmpvar FROM DUAL;
    IF NOT tmpvar = '_' THEN
      winner(tmpvar);
      EXIT;
    END IF;
    -- test des diagonales
    SELECT wincross(tmpx1, crlv.Y, crlv.Y) INTO tmpx1 FROM dual;
    SELECT wincross(tmpx2, 4-crlv.Y, crlv.Y) INTO tmpx2 FROM dual;
  END LOOP;
  IF NOT tmpx1 = '_' THEN
    winner(tmpx1);
  END IF;
  IF NOT tmpx2 = '_' THEN
    winner(tmpx2);
  END IF;
END;
/
--

EXECUTE reset_game;
EXECUTE play('X', 1, 3);
EXECUTE play('O', 2, 1);
EXECUTE play('X', 2, 2);
EXECUTE play('O', 2, 3);
EXECUTE play('X', 3, 1);
