public class AddPrimaryContact implements Queueable {

	public String state;
	public Contact con;

	public AddPrimaryContact(Contact con, String state){
		this.state = state;
		this.con = con;
	}

	public void execute(QueueableContext context) {
        //Do some action here
        List<account> accs =[Select Id, Name, (Select Id, Name From Contacts ) From Account Where BillingState = : state Limit 200];

        List<Contact> lstContact = new List<Contact>();

        for(Account ac : accs){
        	Contact cont = con.clone(false,false,false,false);
        	cont.AccountId =  ac.id;
        	lstContact.add( cont );
        }

        insert lstContact;
	}
}