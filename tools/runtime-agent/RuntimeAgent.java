import java.lang.instrument.Instrumentation;

public class RuntimeAgent {
    public static void premain(String agentArgs, Instrumentation inst) {
        System.out.println("[RuntimeAgent] Starting runtime dependency logger...");
        inst.addTransformer(new RuntimeClassLogger());
    }
}
