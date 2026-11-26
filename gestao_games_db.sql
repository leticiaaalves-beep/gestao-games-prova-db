CREATE TABLE jogadores(
id serial PRIMARY KEY,
nickname VARCHAR(150) not null unique,
email VARCHAR(150) not null unique,
senha VARCHAR(10) not null,
ativo BOOLEAN not null default true

)

CREATE TABLE modalidades(
id serial PRIMARY KEY,
nome VARCHAR(150)

)

CREATE TABLE torneios(
id serial PRIMARY KEY,
nome VARCHAR(150),
data_inicio  date,
data_fim  date

)

CREATE TABLE partidas(
id serial PRIMARY KEY,
id_torneio int not null,
FOREIGN KEY (id_torneio) REFERENCES torneios(id),
id_jogadores int not null,
foreign key (id_jogadores) REFERENCES jogadores(id),
id_modalidade int not null,
foreign key (id_modalidade) REFERENCES modalidades(id),
titulo varchar(150) not null,
data_agendada date,
data_criacao date,
status varchar(100) not null default 'agendada'

)

CREATE TABLE historico_partidas (
    id SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
	 FOREIGN KEY (id_partida) REFERENCES partidas(id),
    descricao VARCHAR(150) NOT NULL,
    data_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	)


INSERT INTO jogadores (nickname, email, senha, ativo) VALUES
('Shadow', 'shadow@email.com', '123456', TRUE),
('Ninja', 'ninja@email.com', '123456', TRUE),
('DarkWolf', 'darkwolf@email.com', '123456', FALSE);


INSERT INTO modalidades (nome) VALUES
('Valorant'),
('League of Legends'),
('Counter-Strike 2');

INSERT INTO torneios (nome, data_inicio, data_fim) VALUES
('Copa Gamer 2026', '2026-11-01', '2026-12-01'),
('Campeonato Elite', '2026-11-10', '2026-12-10'),
('Desafio E-sports', '2026-11-15', '2026-12-15');

INSERT INTO partidas ( id_torneio,id_jogador,id_modalidade,titulo,data_agendada,status) VALUES        //id bugado 2, 3, 4
(1, 1, 1, 'Shadow vs Ninja', '2026-11-28', 'Agendada'),
(2, 2, 2, 'Ninja vs Player01', '2026-11-29', 'Agendada'),
(3, 1, 3, 'Shadow vs DarkWolf', '2026-12-02', 'Em andamento');



INSERT INTO historico_partidas (id_partida,descricao) VALUES
(2, 'Partida cadastrada no sistema.'),
(3, 'Partida cadastrada no sistema.'),
(4, 'Partida cadastrada no sistema.');


CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM jogadores
        WHERE id = NEW.id_jogadores
        AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Jogador inexistente ou inativo!';
    END IF;

    NEW.data_criacao = CURRENT_DATE;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();

CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO historico_partidas (
        id_partida,
        descricao
    )
    VALUES (
        NEW.id,
        'Nova partida cadastrada.'
    );

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();



CREATE OR REPLACE FUNCTION fn_buscar_jogadores(
    termo_busca TEXT
)
RETURNS TABLE (
    id INTEGER,
    nickname VARCHAR(150),
    email VARCHAR(150),
    ativo BOOLEAN
)
AS $$
BEGIN

    RETURN QUERY
    SELECT
        jogadores.id,
        jogadores.nickname,
        jogadores.email,
        jogadores.ativo
    FROM jogadores
    WHERE jogadores.nickname ILIKE '%' || termo_busca || '%'
    OR jogadores.email ILIKE '%' || termo_busca || '%';

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    jogadores.nickname,
    partidas.titulo,
    modalidades.nome AS categoria,
    partidas.data_agendada,
    partidas.status
FROM partidas
INNER JOIN jogadores
    ON partidas.id_jogadores = jogadores.id
INNER JOIN modalidades
    ON partidas.id_modalidade = modalidades.id;


CREATE OR REPLACE VIEW vw_cronograma_partidas AS
SELECT
    partidas.id,
    partidas.titulo,
    jogadores.nickname,
    partidas.data_agendada,
    partidas.status,
    (partidas.data_agendada - CURRENT_DATE) AS dias_restantes
FROM partidas
INNER JOIN jogadores
    ON partidas.id_jogadores = jogadores.id
ORDER BY partidas.data_agendada ASC;


