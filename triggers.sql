-- Criação da tabela Produtos
CREATE TABLE Produtos (
    Prd_Falta INT,
    Prd_Qtd_Estoque INT,
    Prd_Codigo INT PRIMARY KEY,
    Prd_Descricao VARCHAR(255),
    Prd_Valor DECIMAL(10,2),
    Prd_Status VARCHAR(50)
);

-- Inserção de dados na tabela Produtos
INSERT INTO Produtos (Prd_Falta, Prd_Qtd_Estoque, Prd_Codigo, Prd_Descricao, Prd_Valor, Prd_Status)
VALUES 
    (0, 100, 1, 'Produto 1', 50.00, 'Ativo'),
    (1, 50, 2, 'Produto 2', 75.00, 'Inativo'),
    (0, 200, 3, 'Produto 3', 25.00, 'Ativo');

-- Criação da tabela Orcamentos_produtos
CREATE TABLE Orcamentos_produtos (
    Orp_Qtd INT,
    Orp_Valor DECIMAL(10,2),
    Orc_Codigo INT,
    Orp_Status VARCHAR(50),
    Prd_Codigo INT,
    FOREIGN KEY (Orc_Codigo) REFERENCES Orcamentos(Orc_Codigo),
    FOREIGN KEY (Prd_Codigo) REFERENCES Produtos(Prd_Codigo)
);

-- Inserção de dados na tabela Orcamentos_produtos
INSERT INTO Orcamentos_produtos (Orp_Qtd, Orp_Valor, Orc_Codigo, Orp_Status, Prd_Codigo)
VALUES 
    (2, 100.00, 1, 'Ativo', 1),
    (1, 75.00, 2, 'Inativo', 2),
    (3, 50.00, 3, 'Ativo', 3);

-- Criação da tabela Orcamentos
CREATE TABLE Orcamentos (
    Orc_Codigo INT PRIMARY KEY,
    Orc_Data DATE,
    Orc_Status VARCHAR(50)
);

-- Inserção de dados na tabela Orcamentos
INSERT INTO Orcamentos (Orc_Codigo, Orc_Data, Orc_Status)
VALUES 
    (1, '2023-05-01', 'Ativo'),
    (2, '2023-05-02', 'Inativo'),
    (3, '2023-05-03', 'Ativo');
    
    
DELIMITER
CREATE TRIGGER trg_altera_estoque_orcamentos_produtos
AFTER INSERT OR UPDATE ON Orcamentos_produtos
FOR EACH ROW
BEGIN
    -- Verifica se o Orp_Status foi alterado para 2 (cancelado)
    IF NEW.Orp_Status = 2 THEN
        -- Se o Orp_Status for 2, aumenta o estoque do produto
        UPDATE Produtos SET Prd_Qtd_Estoque = Prd_Qtd_Estoque + NEW.Orp_Qtd WHERE Prd_Codigo = NEW.Prd_Codigo;
    ELSE
        -- Se o Orp_Status não for 2, diminui o estoque do produto
        UPDATE Produtos SET Prd_Qtd_Estoque = Prd_Qtd_Estoque - NEW.Orp_Qtd WHERE Prd_Codigo = NEW.Prd_Codigo;
    END IF;
END;
DELIMITER ;

SHOW TRIGGERS;

DELIMITER
CREATE TRIGGER trg_produtos_atualizados
AFTER UPDATE ON Produtos
FOR EACH ROW
BEGIN
    DECLARE qtd_anterior INT;
    SET qtd_anterior = OLD.Prd_Qtd_Estoque;

    -- Insere os dados na tabela produtos_atualizados
    INSERT INTO produtos_atualizados (prd_codigo, prd_qtd_anterior, prd_qtd_atualizada, prd_valor)
    VALUES (OLD.Prd_Codigo, qtd_anterior, NEW.Prd_Qtd_Estoque, NEW.Prd_Valor);

    -- Verifica se a quantidade em estoque foi modificada para zero
    IF NEW.Prd_Qtd_Estoque = 0 THEN
        -- Insere os dados na tabela produtos_em_falta
        INSERT INTO produtos_em_falta (prd_codigo, prd_descricao, prd_status)
        VALUES (NEW.Prd_Codigo, NEW.Prd_Descricao, NULL);

        -- Atualiza o prd_status para NULL
        UPDATE Produtos SET Prd_Status = NULL WHERE Prd_Codigo = NEW.Prd_Codigo;

        -- Atualiza o orp_status para NULL em todos os registros da tabela Orcamentos_produtos que referenciam o produto atualizado
        UPDATE Orcamentos_produtos SET Orp_Status = NULL WHERE Prd_Codigo = NEW.Prd_Codigo;
    END IF;
END;
DELIMITER ; 
