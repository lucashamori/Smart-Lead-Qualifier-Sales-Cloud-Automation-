# 🚀 Smart Lead Qualifier: Automação e Qualidade de Dados no Sales Cloud

> **Categoria:** Desenvolvimento Backend (Apex)
> **Nível:** Junior/Pleno
> **Foco:** Sales Cloud, Data Quality, Trigger Framework, Bulkification

## 📖 Visão Geral do Projeto
Este projeto simula um cenário real de uma **Fintech** ou **Imobiliária** que utiliza o Salesforce Sales Cloud. O objetivo foi criar uma "barreira de qualidade" na entrada de novos Leads e automatizar a distribuição de trabalho para a equipe comercial, eliminando a triagem manual.

O projeto foi construído seguindo as melhores práticas de desenvolvimento Salesforce (Enterprise Patterns), garantindo que a solução seja escalável, testável e respeite os limites de governança da plataforma.

---

## 🏢 Cenário de Negócio (O Problema)
A equipe de vendas relatou três problemas principais:
1.  **Dados Incompletos:** Muitos Leads eram cadastrados sem informar a renda mensal, o que impedia a análise de crédito.
2.  **Perda de Timing:** Leads de alto potencial ("Hot Leads") entravam no sistema, mas os vendedores demoravam dias para perceber e ligar.
3.  **Processo Manual:** O gerente de vendas precisava verificar lead por lead para definir a prioridade.

**A Solução Proposta:**
Desenvolver uma automação que:
1.  **Bloqueie** a criação de Leads sem renda informada.
2.  **Classifique** automaticamente o Lead como "Hot" se a renda for superior a R$ 10.000,00.
3.  **Crie uma Tarefa** urgente para o vendedor automaticamente assim que um Lead "Hot" for detectado.

---

## 🛠️ Passo a Passo da Implementação

Abaixo, detalho o processo completo de construção, desde a configuração na Org até o deploy do código.

### 1. Modelagem de Dados (Object Manager)
Antes de iniciar o código, foi necessário preparar o objeto `Lead` para receber os dados financeiros.

* **Ação:** Criação de Campo Customizado.
* **Local:** Setup > Object Manager > Lead > Fields & Relationships.
* **Configuração do Campo:**
    * **Label:** `Renda Mensal`
    * **API Name:** `Renda_Mensal__c`
    * **Type:** `Currency` (16, 2)
    * **Justificativa:** Utilizei o tipo Currency para garantir a formatação correta de moeda e facilitar cálculos futuros.

### 2. Arquitetura de Código (Trigger Handler Pattern)
Para evitar o anti-padrão de escrever lógica complexa dentro do arquivo da Trigger, adotei o **Handler Pattern**.
* **Trigger (`LeadTrigger.trigger`):** Funciona apenas como um "semáforo", detectando o evento e chamando a classe responsável.
* **Classe Handler (`LeadTriggerHandler.cls`):** Contém toda a regra de negócio lógica.
---

## 🏗️ Estrutura da Solução

### 1. Validação e Classificação (`before insert`)
Antes do registro ser salvo no banco de dados, o sistema verifica:
* **Regra de Qualidade:** O campo `Renda_Mensal__c` está preenchido? Se não, impede o salvamento com uma mensagem de erro amigável.
* **Regra de Negócio:** Se `Renda_Mensal__c >= 10.000`, o sistema define automaticamente o `Rating` como **Hot**. Caso contrário, define como **Cold**.

### 2. Automação de Produtividade (`after insert`)
Após o salvamento (quando o Lead já possui um ID):
* O sistema verifica se o Lead foi classificado como **Hot**.
* Gera automaticamente um registro de **Task (Tarefa)** vinculado a este Lead, com prioridade "High" e data de vencimento para "Hoje".

---

## 💻 Snippets de Código (Destaques)

### Trigger Handler Pattern
Utilização de uma classe Handler para manter a Trigger limpa e testável.

```java
public static void afterInsert(List<Lead> newLeads) {
    List<Task> tasksToCreate = new List<Task>();
    
    for (Lead leadRecord : newLeads) {
        if (leadRecord.Rating == 'Hot') {
            Task newTask = new Task();
            newTask.Subject = 'Ligar para Lead VIP Urgentemente';
            newTask.WhoId = leadRecord.Id; // Vinculação via ID
            tasksToCreate.add(newTask);
        }
    }
    // Bulkification: DML operation fora do loop
    if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }

```

### Test Driven Development (Unit Tests)
Garantia de qualidade cobrindo cenários de sucesso e erro.

```Java

@isTest
public class LeadTriggerTest {

    // Cenário 1: Inserir Lead com Renda Alta (Deve ficar Hot e criar Tarefa)
    @isTest
    static void testLeadHot() {
        Lead leadVip = new Lead();
        leadVip.LastName = 'Teste VIP';
        leadVip.Company = 'Empresa Teste';
        leadVip.Renda_Mensal__c = 15000; // Maior que 10k
        
        Test.startTest();
        insert leadVip;
        Test.stopTest();
        
        // Verificações (Asserts)
        Lead insertedLead = [SELECT Rating FROM Lead WHERE Id = :leadVip.Id];
        System.assertEquals('Hot', insertedLead.Rating, 'O Lead deveria ser classificado como Hot');
        
        // Verifica se a tarefa foi criada
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhoId = :leadVip.Id];
        System.assertEquals(1, tasks.size(), 'Deveria ter sido criada 1 tarefa');
    }

    // Cenário 2: Tentar inserir sem Renda (Deve dar erro)
    @isTest
    static void testLeadValidation() {
        Lead leadSemRenda = new Lead();
        leadSemRenda.LastName = 'Teste Erro';
        leadSemRenda.Company = 'Empresa Erro';
        // Não preenchemos a renda
        
        Test.startTest();
        try {
            insert leadSemRenda;
        } catch (Exception e) {
            // Verifica se a mensagem de erro é a que definimos
            Boolean expectedExceptionThrown = e.getMessage().contains('O campo Renda Mensal é obrigatório');
            System.assert(expectedExceptionThrown, 'Deveria ter lançado o erro de validação');
        }
        Test.stopTest();
    }
}
```
### Impacto Esperado
* 100% de conformidade nos dados de renda de novos Leads.
* Redução do tempo de resposta para clientes VIP (Hot Leads) devido à criação automática de tarefas.
* Código escalável pronto para suportar cargas de dados em massa (Data Loader) sem atingir Governor Limits.


### 👨‍💻 Autor
**Lucas Mori**
Estudante de Desenvolvimento de Sistemas & Salesforce Enthusiast.

