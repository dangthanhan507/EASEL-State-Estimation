classdef ARPOD_Benchmark
    properties (Constant)
        t_e = 14400; % eclipse time (in seconds)
        t_f = 43200; % total mission duration (in seconds)
        rho_r = 1; % maximum distance for range measurements (1 km)
        rho_d = 0.1; % docking phase initial radius (0.1 km)
        m_t = 2000; % mass of target (2000 kg)
        m_c = 500; % mass of chaser (500 kg)
        mu = 398600.4; %earth's gravitational constant (in km^3/s^2)
        a = 42164; % semi-major axis of GEO (42164 km)
        Vbar = 5 * 10.^(-5); % max closing velocity while docking (in km/s)
        theta = 60; % LOS Constraint angle (in degrees)
        c = [-1;0;0]; % LOS cone direction
        x_docked = [0;0;0;0;0;0]; % docked position in km, and km/s
        x_relocation = [0;20;0;0;0;0]; %relocation position in km, km/s
        x_partner = [0;30;0;0;0;0]; %partner position in km, km/s

        % can choose to add noise separately
    end
    methods (Static)
        function phase = calculatePhase(traj, reached)
            norm = traj(:,1:3);
            norm = sqrt(norm.^2);
            if (reached == 0)
                if (norm > 1)
                    % ARPOD phase 1: Rendezvous w/out range
                    phase = 1;
                elseif (norm > 0.1) 
                    % ARPOD phase 2: Rendezvous with range
                    phase = 2;
                else 
                    %ARPOD phase 3: Docking
                    phase = 3;
                end
            else
                % ARPOD phase 4: Rendezvous to new location
                phase = 4;
            end
        end
        function traj = nextStep(traj0, u, timestep, noise, options)
            if (options == 1)
                % discrete control input
                u0 = @(t) u;
                [ts, trajs] = nonlinearChaserDynamics.simulateMotion(traj0, ARPOD_Benchmark.a, u0, timestep, timestep);
                traj = trajs(2,:);
            elseif (options == 2)
                % discrete impulsive control input
                % To be Implemented
                disp('it is not implemented!. What are you doing?');
            elseif (options == 3)
                % continuous control input
                [ts, trajs] = nonlinearChaserDynamics.simulateMotion(traj0, ARPOD_Benchmark.a, u,timestep,timestep);
                traj = trajs(2,:);
            end
            traj = traj + noise();
        end
        function sensor = sensor(state, noise, options)
            if (options == 1)
                %phase 1: only using bearing measurements
                sensor = ARPOD.measure(state);
                sensor = sensor(1:2,:);
            elseif (options == 2)
                %phase 2: bearing measurements + range measurement
                sensor = ARPOD.measure(state);
            elseif (options == 3)
                %phase 3: same as phase 2
                sensor = ARPOD.measure(state);
            elseif (options == 4)
                %phase 4: relative phase 2 to partner spacecraft
                r = ARPOD_Benchmark.x_partner - [state(1);state(2);state(3)]; % relative position to partner spacecraft
                sensor = ARPOD.measure(r);
            end
            sensor = sensor + noise();
        end
    end
end