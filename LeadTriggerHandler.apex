public with sharing class LeadTriggerHandler {
    
    // Método para rodar ANTES de salvar (Validações e preenchimento automático)
    public static void beforeInsert(List<Lead> newLeads) {
        for (Lead leadRecord : newLeads) {
            // Regra 1: Validação - Renda é obrigatória
            if (leadRecord.Renda_Mensal__c == null) {
                leadRecord.addError('O campo Renda Mensal é obrigatório para novos Leads.');
            }
            
            // Regra 2: Automação - Se Renda > 10k, o Lead é "Hot" (Quente)
            if (leadRecord.Renda_Mensal__c >= 10000) {
                leadRecord.Rating = 'Hot';
            } else {
                leadRecord.Rating = 'Cold';
            }
        }
    }

    // Método para rodar DEPOIS de salvar (Criar registros relacionados)
    public static void afterInsert(List<Lead> newLeads) {
        List<Task> tasksToCreate = new List<Task>();
        
        for (Lead leadRecord : newLeads) {
            // Regra 3: Se o Lead for Hot, criar uma tarefa para o vendedor ligar hoje
            if (leadRecord.Rating == 'Hot') {
                Task newTask = new Task();
                newTask.Subject = 'Ligar para Lead VIP Urgentemente';
                newTask.Priority = 'High';
                newTask.Status = 'Not Started';
                newTask.WhoId = leadRecord.Id; // Vincula a tarefa ao Lead criado
                newTask.OwnerId = leadRecord.OwnerId; // Atribui ao dono do Lead
                newTask.ActivityDate = Date.today();
                
                tasksToCreate.add(newTask);
            }
        }
        
        // BOAS PRÁTICAS: Fazer o insert fora do loop (Bulkification)
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}
