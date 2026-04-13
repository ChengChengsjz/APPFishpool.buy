package cacom.example.smarthome;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.app.Service;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Vibrator;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class MainActivity extends AppCompatActivity {

    TextView WtrTempVal, WtrLevelVal,LightVal,TurbVal,PHVal,WtrTempThreshold, WtrLevelThreshold, LightThreshold,PHMax,PHMin,TurbThreshold,Automatic,TimeFlag,ThresholdMODE,Manual,shi,fen,miao,gotime;
    Switch Switch1,Switch2,Switch3,Switch4,Switch5,Switch6,Switch7,TimeMode_Selection,TimeMode_Switch;
    ProgressBar p1,p2,p3,p4,p5;
    ImageView WtrTempThresholdDown,WtrTempThresholdAdd,WtrLevelThresholdDown,WtrLevelThresholdAdd,LightThresholdDown,LightThresholdAdd,TurbThersholdDown,TurbThersholdAdd,PHMaxDown,PHMinDown,PHMinAdd,PHMaxAdd,HourDown,HourAdd,MinuteDown,MinuteAdd,TimeDown,TimeAdd;
    LinearLayout layout1,layout2,layout3,onoroff;
    AlertDialog.Builder builder;
    AlertDialog alertDialog;
    int math = (int) ((Math.random() * 9 + 1) * (10000));
    String mqttid="sadjk"+String.valueOf(math);
    private ScheduledExecutorService scheduler;
    private MqttClient client;
    private MqttConnectOptions options;
    private Handler handler;
    private String host = "tcp://47.109.89.8:1883";     // TCP协议
    private String userName = "root23";
    private String passWord = "root34";
    private String mqtt_id = mqttid;
    private String mqtt_sub_topic = "";
    private String mqtt_pub_topic = "";

    private SharedPreferences sharedPreferences;
    private AlertDialog loginDialog;


    //
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        sharedPreferences = getSharedPreferences("UserData", MODE_PRIVATE);


        Control_initialization();
        showLoginDialog(() -> {
            // 对话框关闭后执行的核心逻辑
            initializeAfterLogin();
        });



    }

    private void showLoginDialog(Runnable onSuccess) {
        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_login, null);
        EditText etUsername = dialogView.findViewById(R.id.et_username);
        EditText etPassword = dialogView.findViewById(R.id.et_password);

        // 自动填充已保存数据
        String savedUsername = sharedPreferences.getString("username", "");
        String savedPassword = sharedPreferences.getString("password", "");
        etUsername.setText(savedUsername);
        etPassword.setText(savedPassword);

        // 构建不可取消的对话框
        loginDialog = new AlertDialog.Builder(this)
                .setTitle(savedUsername.isEmpty() ? "首次输入" : "确认主题")
                .setView(dialogView)
                .setPositiveButton("确定", null) // 先设为null
                .setNegativeButton("取消", (dialog, which) -> finish())
                .setCancelable(false) // 禁用返回键和外部点击
                .create();

        // 自定义确定按钮逻辑
        loginDialog.setOnShowListener(dialogInterface -> {
            Button positiveButton = loginDialog.getButton(AlertDialog.BUTTON_POSITIVE);
            positiveButton.setOnClickListener(v -> {
                String username = etUsername.getText().toString().trim();
                String password = etPassword.getText().toString().trim();

                // 清除旧错误提示
                etUsername.setError(null);
                etPassword.setError(null);

                // 输入校验
                boolean hasError = false;
                if (username.isEmpty()) {
                    etUsername.setError("不能为空");
                    hasError = true;
                }
                if (password.isEmpty()) {
                    etPassword.setError("不能为空");
                    hasError = true;
                }

                // 校验通过后保存数据并执行后续逻辑
                if (!hasError) {
                    saveUserData(username, password);
                    mqtt_sub_topic=username;
                    mqtt_pub_topic=password;
                    loginDialog.dismiss();
                    onSuccess.run(); // 执行后续初始化
                }
            });
        });

        loginDialog.show();
    }

    private void saveUserData(String username, String password) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("username", username);
        editor.putString("password", password);
        editor.apply();
        showSavedData();
    }

    private void showSavedData() {
        String username = sharedPreferences.getString("username", "未保存");
        String password = sharedPreferences.getString("password", "未保存");

    }

    private void initializeAfterLogin() {
        handler = new Handler(Looper.getMainLooper()) {
            @SuppressLint("SetTextI18n")
            public void handleMessage(Message msg) {
                super.handleMessage(msg);
                switch (msg.what){
                    case 3:
                        if (msg.obj != null) {
                            parseJsonobj(msg.obj.toString());
                        }
                        break;
                    case 30:
                        Toast.makeText(MainActivity.this,"MQTT服务器连接失败" ,Toast.LENGTH_SHORT).show();
                        break;
                    case 31:
                        Toast.makeText(MainActivity.this,"MQTT服务器连接成功,等待硬件数据上报" ,Toast.LENGTH_SHORT).show();
                        try {
                            if (client != null && client.isConnected()) {
                                client.subscribe(mqtt_sub_topic,0);
                            }
                        } catch (MqttException e) {
                            e.printStackTrace();
                        }
                        break;
                    default:
                        break;
                }
            }
        };
        Mqtt_init();
        startReconnect();
        Listen_for_events();
    }
    private void Mqtt_init()
    {
        try {
            client = new MqttClient(host, mqtt_id, new MemoryPersistence());
            options = new MqttConnectOptions();
            options.setCleanSession(false);
            options.setUserName(userName);
            options.setPassword(passWord.toCharArray());
            options.setConnectionTimeout(10);
            options.setKeepAliveInterval(20);

            client.setCallback(new MqttCallback() {
                @Override

                public void connectionLost(Throwable cause) {
                    //连接丢失后，一般在这里面进行重连
                    System.out.println("connectionLost----------");

                    //startReconnect();
                }
                @Override

                public void deliveryComplete(IMqttDeliveryToken token) {
                    //publish后会执行到这里
                    //publishmessageplus(mqtt_pub_topic,"nihao");

                    System.out.println("deliveryComplete---------"
                            + token.isComplete());

                }
                @Override

                public void messageArrived(String topicName, MqttMessage message)
                        throws Exception {

                    //subscribe后得到的消息会执行到这里面
                    System.out.println("messageArrived----------");
                    Message msg = new Message();

                    // parseJsonobj(mqtt_sub_topic);

                    msg.what = 3;   //收到消息标志位
//                    msg.obj = topicName + "---" +message.toString();
                    msg.obj = message.toString();
                    handler.sendMessage(msg);    // hander 回传

                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // MQTT连接函数
    private void Mqtt_connect() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    if(client != null && !client.isConnected())
                    {
                        client.connect(options);
                        Message msg = new Message();
                        msg.what = 31;
                        handler.sendMessage(msg);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    Message msg = new Message();
                    msg.what = 30;
                    handler.sendMessage(msg);
                }
            }
        }).start();
    }

    // MQTT重新连接函数
    private void startReconnect() {

        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(new Runnable() {
            @Override
            public void run() {
                if (!client.isConnected()) {
                    Mqtt_connect();
                }
            }
        }, 0*1000, 10 * 1000, TimeUnit.MILLISECONDS);
    }

    // 订阅函数    (下发任务/命令)
    private void publishmessageplus(String topic,String message2)
    {
        if (client == null || !client.isConnected()) {
            return;
        }
        MqttMessage message = new MqttMessage();
        message.setPayload(message2.getBytes());
        try {
            client.publish(topic,message2.getBytes(),0,false);
            // client.publish(topic,message);
        } catch (MqttException e) {

            e.printStackTrace();
        }
    }
    private void parseJsonobj(String jsonobj){
        try {
            JSONObject jsonObject = new JSONObject(jsonobj);
            String sensor1 = jsonObject.optString("sensor1", "0");
            String sensor2 = jsonObject.optString("sensor2", "0");
            String sensor3 = jsonObject.optString("sensor3", "0");
            String sensor4 = jsonObject.optString("sensor4", "0");
            String sensor5 = jsonObject.optString("sensor5", "0");
            String sensor6 = jsonObject.optString("sensor6", "0");
            String sensor7 = jsonObject.optString("sensor7", "0");
            String sensor8 = jsonObject.optString("sensor8", "0");
            String sensor9 = jsonObject.optString("sensor9", "0");
            String sensor10 = jsonObject.optString("sensor10", "0");
            String sensor11 = jsonObject.optString("sensor11", "0");
            String sensor12 = jsonObject.optString("sensor12", "0");
            String sensor13 = jsonObject.optString("sensor13", "0");
            String sensor14 = jsonObject.optString("sensor14", "0");
            String sensor15 = jsonObject.optString("sensor15", "0");
            String sensor16 = jsonObject.optString("sensor16", "0");
            String sensor17 = jsonObject.optString("sensor17", "0");
            String sensor18 = jsonObject.optString("sensor18", "0");
            String sensor19 = jsonObject.optString("sensor19", "0");
            String sensor20 = jsonObject.optString("sensor20", "0");

            WtrTempVal.setText(sensor1+"°C");
            p3.setProgress(safeParseInt(sensor1));
            WtrLevelVal.setText(sensor2+"mm");
            p4.setProgress(safeParseInt(sensor2));
            LightVal.setText(sensor3+"Lux");
            p2.setProgress(safeParseInt(sensor3));
            TurbVal.setText(sensor4+"NTU");
            p1.setProgress(safeParseInt(sensor4));
            PHVal.setText(sensor5);
            p5.setProgress(safeParseInt(sensor5));
            WtrTempThreshold.setText(sensor6);
            WtrLevelThreshold.setText(sensor7);
            LightThreshold.setText(sensor8);
            TurbThreshold.setText(sensor9);
            PHMax.setText(sensor10);
            PHMin.setText(sensor11);

            int mode = safeParseInt(sensor20);
            if (mode == 0){
              shi.setText(sensor12);
              fen.setText(sensor13);
              miao.setText(sensor14);
              gotime.setText(sensor15);
            } else if (mode == 1){
                shi.setText(sensor16);
                fen.setText(sensor17);
                miao.setText(sensor18);
                gotime.setText(sensor19);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private int safeParseInt(String s) {
        try {
            if (s.contains(".")) {
                return (int) Double.parseDouble(s);
            }
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    //给控件获取id
    private void Control_initialization(){
        //myVibrator = (Vibrator) getSystemService(Service.VIBRATOR_SERVICE);

        TurbVal=findViewById(R.id. Sensor4);
        LightVal=findViewById(R.id.Sensor3);
        WtrTempVal=findViewById(R.id.Sensor2);
        WtrLevelVal=findViewById(R.id.Sensor1);
        PHVal=findViewById(R.id. Sensor5);

        TurbThreshold=findViewById(R.id.Sensor4_Threshold);
        LightThreshold=findViewById(R.id.Sensor3_Threshold);
        WtrTempThreshold=findViewById(R.id.Sensor1_Threshold);
        WtrLevelThreshold=findViewById(R.id.Sensor2_Threshold);
        PHMax=findViewById(R.id.Sensor5_Threshold);
        PHMin=findViewById(R.id.Sensor6_Threshold);

        shi=findViewById(R.id.Sensor6);
        fen=findViewById(R.id.Sensor7);
        miao=findViewById(R.id.Sensor8);

        p1=findViewById(R.id.ss1);
        p2=findViewById(R.id.ss2);
        p3=findViewById(R.id.ss3);
        p4=findViewById(R.id.ss4);
        p5=findViewById(R.id.ss5);


        layout1=findViewById(R.id.Mode1);
        layout2=findViewById(R.id.Mode2);
        layout3=findViewById(R.id.Mode3);
        onoroff=findViewById(R.id.onoroff);

        Automatic=findViewById(R.id.zidong);
        TimeFlag=findViewById(R.id.dingshi);
        ThresholdMODE=findViewById(R.id.yuzhi);
        Manual=findViewById(R.id.shoudong);

        TimeMode_Selection=findViewById(R.id.GoTimeFlag);
        TimeMode_Switch=findViewById(R.id.TimeFlag);
        gotime=findViewById(R.id.GOTIME);

        Switch1=findViewById(R.id.Switch1);
        Switch2=findViewById(R.id.Switch2);
        Switch3=findViewById(R.id.Switch3);
        Switch4=findViewById(R.id.Switch4);
        Switch5=findViewById(R.id.Switch5);
        Switch6=findViewById(R.id.Switch6);
        Switch7=findViewById(R.id.Switch7);

        WtrTempThresholdDown=findViewById(R.id.Sensor1down);
        WtrTempThresholdAdd=findViewById(R.id.Sensor1add);
        WtrLevelThresholdDown=findViewById(R.id.Sensor2down);
        WtrLevelThresholdAdd=findViewById(R.id.Sensor2add);
        TurbThersholdDown=findViewById(R.id.Sensor4down);
        TurbThersholdAdd=findViewById(R.id.Sensor4add);
        LightThresholdAdd=findViewById(R.id.Sensor3add);
        LightThresholdDown=findViewById(R.id.Sensor3down);
        PHMaxAdd=findViewById(R.id.Sensor8add);
        PHMaxDown=findViewById(R.id.Sensor8down);
        PHMinAdd=findViewById(R.id.Sensor9add);
        PHMinDown=findViewById(R.id.Sensor9down);
        HourDown=findViewById(R.id.Sensor5down);
        HourAdd=findViewById(R.id.Sensor5add);
        MinuteDown=findViewById(R.id.Sensor6down);
        MinuteAdd=findViewById(R.id.Sensor6add);
        TimeDown=findViewById(R.id.Sensor7down);
        TimeAdd=findViewById(R.id.Sensor7add);

        layout1.setVisibility(View.GONE);
        layout2.setVisibility(View.GONE);
        layout3.setVisibility(View.GONE);
    }
    //监听事件
    private void Listen_for_events(){

        Automatic.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View view) {
        layout1.setVisibility(View.GONE);
        layout2.setVisibility(View.GONE);
        layout3.setVisibility(View.GONE);

        Automatic.setBackgroundResource(R.drawable.onbanck);
        TimeFlag.setBackgroundResource(R.drawable.lin_shape);
        ThresholdMODE.setBackgroundResource(R.drawable.lin_shape);
        Manual.setBackgroundResource(R.drawable.lin_shape);
        publishmessageplus(mqtt_pub_topic,"Automatic");
    }
});

        TimeFlag.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                layout1.setVisibility(View.GONE);
                layout2.setVisibility(View.GONE);
                layout3.setVisibility(View.VISIBLE);

                Automatic.setBackgroundResource(R.drawable.lin_shape);
                TimeFlag.setBackgroundResource(R.drawable.onbanck);
                ThresholdMODE.setBackgroundResource(R.drawable.lin_shape);
                Manual.setBackgroundResource(R.drawable.lin_shape);
                publishmessageplus(mqtt_pub_topic,"TimeFlag");
            }
        });

        ThresholdMODE.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                layout1.setVisibility(View.GONE);
                layout2.setVisibility(View.VISIBLE);
                layout3.setVisibility(View.GONE);

                Automatic.setBackgroundResource(R.drawable.lin_shape);
                TimeFlag.setBackgroundResource(R.drawable.lin_shape);
                ThresholdMODE.setBackgroundResource(R.drawable.onbanck);
                Manual.setBackgroundResource(R.drawable.lin_shape);
                publishmessageplus(mqtt_pub_topic,"ThresholdMODE");
            }
        });
        Manual.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                layout1.setVisibility(View.VISIBLE);
                layout2.setVisibility(View.GONE);
                layout3.setVisibility(View.GONE);
                Automatic.setBackgroundResource(R.drawable.lin_shape);
                TimeFlag.setBackgroundResource(R.drawable.lin_shape);
                ThresholdMODE.setBackgroundResource(R.drawable.lin_shape);
                Manual.setBackgroundResource(R.drawable.onbanck);
                publishmessageplus(mqtt_pub_topic,"Manual");
            }
        });

        TimeMode_Selection.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"OxMode");
                }else {
                    publishmessageplus(mqtt_pub_topic,"FeedMode");
                }
            }
        });

        TimeMode_Switch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean b) {
                if (b){
                    publishmessageplus(mqtt_pub_topic,"TimeON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"TimeOFF");
                }
            }
        });

        WtrTempThresholdDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {publishmessageplus(mqtt_pub_topic,"WtrTempThresholdDown");
            }
        });

        WtrTempThresholdAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {publishmessageplus(mqtt_pub_topic,"WtrTempThresholdAdd");
            }
        });

        WtrLevelThresholdDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {publishmessageplus(mqtt_pub_topic,"WtrLevelThresholdDown");
            }
        });

        WtrLevelThresholdAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"WtrLevelThresholdAdd");
            }
        });

        LightThresholdDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"LightThresholdDown");
            }
        });

        LightThresholdAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"LightThresholdAdd");
            }
        });


        TurbThersholdDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"TurbThersholdDown");
            }
        });

        TurbThersholdAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"TurbThersholdAdd");
            }
        });

        HourDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"HourDown");
            }
        });
        HourAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"HourAdd");
            }
        });

        MinuteDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"MinuteDown");
            }
        });

        MinuteAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"MinuteAdd");
            }
        });

        TimeDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"TimeDown");
            }
        });

        TimeAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"TimeAdd");
            }
        });

        PHMinDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"PHMinDown");
            }
        });

        PHMinAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"PHMinAdd");
            }
        });

        PHMaxDown.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"PHMaxDown");
            }
        });

        PHMaxAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                publishmessageplus(mqtt_pub_topic,"PHMaxAdd");
            }
        });

        Switch1.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch1ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch1OFF");
                }
            }
        });

        Switch2.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch2ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch2OFF");
                }
            }
        });

        Switch3.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch3ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch3OFF");
                }
            }
        });

        Switch4.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch4ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch4OFF");
                }
            }
        });


        Switch5.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch5ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch5OFF");
                }
            }
        });
        Switch6.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch6ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch6OFF");
                }
            }
        });

        Switch7.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked){
                    publishmessageplus(mqtt_pub_topic,"Switch7ON");
                }else {
                    publishmessageplus(mqtt_pub_topic,"Switch7OFF");
                }
            }
        });

    }
}