import java.lang.instrument.ClassFileTransformer;
import java.security.ProtectionDomain;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;
import java.nio.file.*;

public class RuntimeClassLogger implements ClassFileTransformer {
    private static final Set<String> loadedClasses = Collections.synchronizedSet(new HashSet<>());
    private static final Path outputPath = Paths.get("sbom/runtime/runtime-loaded.json");

    static {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                Files.createDirectories(outputPath.getParent());
                Map<String, Object> data = new HashMap<>();
                data.put("runtime_dependencies", new ArrayList<>(loadedClasses));
                try (FileWriter writer = new FileWriter(outputPath.toFile())) {
                    writer.write(toJson(data));
                }
                System.out.println("[RuntimeAgent] Runtime dependency log saved to " + outputPath);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }));
    }

    @Override
    public byte[] transform(Module module, ClassLoader loader, String className,
                            Class<?> classBeingRedefined, ProtectionDomain protectionDomain,
                            byte[] classfileBuffer) {
        if (className != null && !className.startsWith("java/") && !className.startsWith("sun/")) {
            String jar = (protectionDomain != null && protectionDomain.getCodeSource() != null)
                    ? protectionDomain.getCodeSource().getLocation().toString()
                    : "unknown";
            loadedClasses.add(jar + "::" + className.replace('/', '.'));
        }
        return null;
    }

    private static String toJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{\n  \"runtime_dependencies\": [\n");
        @SuppressWarnings("unchecked")
        List<String> deps = (List<String>) map.get("runtime_dependencies");
        for (int i = 0; i < deps.size(); i++) {
            sb.append("    \"").append(deps.get(i)).append("\"");
            if (i < deps.size() - 1) sb.append(",");
            sb.append("\n");
        }
        sb.append("  ]\n}\n");
        return sb.toString();
    }
}
