package com.gooddata.lcm.statistics;


import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gooddata.GoodData;
import com.gooddata.project.Project;
import com.opencsv.CSVWriter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.stream.StreamSupport;

import static java.lang.String.format;

public class LcmStatisticsLoader {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    private final GoodData gd;

    private final ObjectMapper mapper = new ObjectMapper();

    public LcmStatisticsLoader(GoodData gd) {
        this.gd = gd;
    }

    public void dumpToCsv(File inputJson, File outputCsv) {

        try (final CSVWriter csvWriter =
                         new CSVWriter(new OutputStreamWriter(new FileOutputStream(outputCsv), StandardCharsets.UTF_8))) {

            final JsonNode root = mapper.readTree(inputJson);
            System.out.println(root.getNodeType());

            csvWriter.writeNext(new String[] {
                    "f_executions.nm_executionid",
                    "d_executions_processid.nm_processid",
                    "d_executions_projectid.nm_projectid",
                    "d_executions_trigger.nm_trigger",
                    "d_executions_profilelogin.nm_profilelogin",
                    "f_executions.f_executiontimeseconds",
                    "f_executions.dt_executioncreated_id",
                    "d_executions_hourofday.nm_hourofday",
                    "d_executions_status.nm_status",
                    "d_executions_bricktype.nm_bricktype"
            });
            if (root.isArray()) {
                System.out.println(root.size());
                StreamSupport.stream(root.spliterator(), false).map(n -> n.get("execution")).forEach(e -> {

                    final String executionId = getTextNode(e, "executionId");
                    final String processId = getTextNode(e, "processId");
                    final String profileLogin = getTextNode(e, "profileLogin");
                    final String projectId = getTextNode(e, "projectId");
                    final String trigger = getTextNode(e, "trigger");
                    final String status = getTextNode(e, "status");

                    //final String processGitPath = getTextNode(e, "processGitPath");
                    final String brickType = getTextNode(e, "brickType");


                    final Long startTimeMillis = getLongNode(e, "startTime");
                    final Long endTimeMillis = getLongNode(e, "endTime");

                    final Long excutionTimeSeconds = startTimeMillis != null && endTimeMillis != null ? (endTimeMillis - startTimeMillis) / 1000 : null;

                    final DateTimeFormatter gdcDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

                    final String startDate;
                    final String startDateHour;
                    if (startTimeMillis != null) {
                        LocalDateTime startTime = LocalDateTime.ofInstant(Instant.ofEpochMilli(startTimeMillis), ZoneId.of("UTC"));

                        startDate = startTime.format(gdcDateFormatter);
                        startDateHour = Integer.toString(startTime.getHour());
                    } else {
                        startDate = "";
                        startDateHour = "";
                    }


                    csvWriter.writeNext(new String[] {
                            executionId,
                            processId,
                            projectId,
                            trigger,
                            profileLogin,
                            excutionTimeSeconds != null ? excutionTimeSeconds.toString() : null,
                            startDate,
                            startDateHour,
                            status,
                            brickType
                    });
                });
            }

            csvWriter.flush();
        } catch (IOException e) {
            throw new LcmStatisticsException(format("Error writing CSV file '%s': %s", outputCsv.getAbsolutePath(),
                    e.getMessage()), e);
        }
    }

    private Long getLongNode(JsonNode e, String value) {
        final JsonNode node = e.get(value);
        return node != null ? node.asLong() : null;
    }

    private String getTextNode(JsonNode e, String value) {
        final JsonNode node = e.get(value);
        return node != null ? node.asText() : "";
    }

    public void load(File executionsJson) {
        logger.info("status=start");
        final Project project = gd.getProjectService().getProjectById("ezikw7c493tffxz3hq3yqbd7i716ewkd");
        final File temp = new File("/tmp");
        final File outputCsv = new File(temp, "executions.csv");
        dumpToCsv(executionsJson, outputCsv);
        try(InputStream uploadCsv = new FileInputStream(outputCsv)) {

            gd.getDatasetService().loadDataset(project, "dataset.executions", uploadCsv).get();

        } catch (FileNotFoundException e) {
            throw new LcmStatisticsException("Upload file does not exists: " + outputCsv.getAbsolutePath(), e);
        } catch (IOException e) {
            throw new LcmStatisticsException(e);
        }
        logger.info("status=finished");
    }

    public static void main(String[] args) {
        final GoodData gd = new GoodData("adam.stulpa@gooddata.com", "xxx");
        try {
            new LcmStatisticsLoader(gd).load(new File("/home/adam/data-gdc/repos/lcm-statistics/lcmExec_n2.json"));
        } finally {
            gd.logout();
        }
    }
}
