# 🚀 Smart Lead Qualifier (Sales Cloud Automation)

> **Foco:** Backend Automation & Data Integrity

Este projeto implementa uma automação robusta de backend para o ecossistema **Salesforce Sales Cloud**. O objetivo é eliminar a entrada de dados inconsistentes (Data Quality) e automatizar a priorização de Leads para a equipe comercial, utilizando Apex Triggers seguindo as melhores práticas de Enterprise Design Patterns.

---

## 💼 Cenário de Negócio
Uma empresa do setor financeiro enfrentava dois problemas críticos:
1.  **Dados Sujos:** Criação de Leads sem informações financeiras essenciais para a análise de crédito.
2.  **Lead Time:** Vendedores demoravam para identificar e contatar Leads de alto potencial ("Hot Leads"), perdendo oportunidades de venda.

**Solução:** Desenvolvi uma automação que intercepta a criação do Lead, valida obrigatoriedade de campos condicionalmente, classifica o cliente automaticamente baseado na renda e agenda tarefas de follow-up para os vendedores.

---

## 🛠️ Stack Tecnológico & Conceitos Aplicados

* **Salesforce Sales Cloud** (Objeto Lead & Task)
* **Apex Triggers** (Eventos `before insert`, `after insert`)
* **Trigger Handler Pattern** (Separação lógica para escalabilidade)
* **Apex Unit Tests** (100% de cobertura de código com Asserts positivos/negativos)
* **Bulkification** (Código preparado para grandes volumes de dados/Data Loader)
* **Data Integrity** (Validação via `addError`)

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

